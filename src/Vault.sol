// SPDX-License-Identifier: MIT
// pragma solidity 0.8.33;
pragma solidity ^0.8.0;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {BaseStrategy} from "./BaseStrategy.sol";
/**
    функция присваивания роли БОТу

    ограничить ребалансировку и отчет бота 
    отдельный emergency admin
 */

contract Vault is ERC4626, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint internal constant BPS = 10_000;
    uint internal constant MAXIMUM_STRATEGIES = 20;
    uint16 internal constant DEFAULT_PERFORMANCE_FEE = 100;
    uint16 internal constant DEFAULT_MANAGMENT_FEE = 100;
    uint16 internal constant MAX_PERSENT = 10_000;
    uint16 internal constant MIN_PERSENT = 1;

    /// @notice Seconds per year for max profit unlocking time.
    uint256 internal constant SECONDS_PER_YEAR = 31_556_952; // 365.2425 days

    uint16 _managementFee; // The percent in basis points of profit that is charged as a fee.
    address _feeRecipient; // The address to pay the `performanceFee` to.
    BaseStrategy[MAXIMUM_STRATEGIES] withdrawQueue;

    bytes32 constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    struct StrategyInfo {
        uint balance;
        uint96 lastTakeTime;
        uint16 sharePercent;
        uint16 performanceFee;// The percent in basis points of profit that is charged as a fee.
    }
    mapping (BaseStrategy => StrategyInfo) strategyInfoMap;

//
    constructor(IERC20 assetToken_, string memory nameShare_, string memory sybolShare_, address manager_, address feeRecipient_) 
        ERC4626(assetToken_) 
        ERC20(nameShare_, sybolShare_) 
    {
        require(feeRecipient_ != address(0), "feeRecipient zero address");
        require(address(assetToken_) != address(0), "assetToken zero address");
        require(manager_ != address(0), "manager zero address");

        _managementFee = DEFAULT_MANAGMENT_FEE;
        _feeRecipient = feeRecipient_;
        
        _grantRole(DEFAULT_ADMIN_ROLE, manager_);
    }

    modifier checkBorderBPS(uint16 num) {
        _checkBorderBPS(num);
        _;
    }

    function _checkBorderBPS(uint16 num) internal pure{
        require(num >= uint16(MIN_PERSENT), "min % is 0,01");
        require(num <= uint16(MAX_PERSENT), "max % is 100");
    }

    modifier checkAsset(BaseStrategy strategy) {
        _checkAsset(strategy);
        _;
    }

    function _checkAsset(BaseStrategy strategy) internal view {
        require (strategy.asset() == address(asset()), "bad strategy asset in");
    }

    
    modifier checkVault(BaseStrategy strategy) {
        _checkVault(strategy);
        _;
    }

    function _checkVault(BaseStrategy strategy) internal view {
        require (strategy.vault() == address(this), "bad strategy vault in");
    }

    modifier notPaused(BaseStrategy strategy) {
        _notPaused(strategy);
        _;
    }

    function _notPaused(BaseStrategy strategy) internal view{
        require(!strategy.isPaused(), "is paused");
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /**
     * @notice Emitted when the 'keeper' address is updated to 'newKeeper'.
     */
    event UpdateKeeper(address indexed newKeeper);
    
    /**
     * @notice Emitted when the 'management' address is updated to 'newManagement'.
     */
    event UpdateManagement(address indexed newManagement);

//
    function add(BaseStrategy newStrategy, uint16 sharePercent) external onlyRole(DEFAULT_ADMIN_ROLE) checkAsset(newStrategy) checkVault(newStrategy){
        require (IERC20(asset()).allowance(address(newStrategy), address(this)) == type(uint256).max, "must allowance type(uint256).max");
        require (address(withdrawQueue[MAXIMUM_STRATEGIES - 1]) == address(0), "limited of strategy");

        StrategyInfo storage info = strategyInfoMap[newStrategy];

        require (info.sharePercent == 0, "strategy exist");

        for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
            if (address(withdrawQueue[i]) == address(0)) {
                withdrawQueue[i] = newStrategy;
                break;
            }
        }

        setSharePercent(newStrategy, sharePercent);
        info.lastTakeTime = uint96(block.timestamp);
        info.performanceFee = DEFAULT_PERFORMANCE_FEE;

        emit StrategyAdded(address(newStrategy));
    }

    function migrate(BaseStrategy oldStrategy, BaseStrategy newStrategy) external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        checkAsset(newStrategy)
        checkVault(newStrategy)
    {
        require (strategyInfoMap[newStrategy].sharePercent == 0, "strategy alredy exist");
        StrategyInfo memory info = strategyInfoMap[oldStrategy];

        delete strategyInfoMap[oldStrategy];

        for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
            if (address(withdrawQueue[i]) == address(oldStrategy)) {
        
                withdrawQueue[i] = newStrategy;
                strategyInfoMap[newStrategy] = StrategyInfo({ 
                    balance: info.balance, 
                    lastTakeTime: uint96(block.timestamp), 
                    sharePercent: info.sharePercent, 
                    performanceFee: info.performanceFee 
                });

                _report(oldStrategy);
                uint balance = oldStrategy.pull(info.balance);

                // strategyInfoMap[newStrategy].balance = balance;
                newStrategy.push(balance);
                break;
            }
        }
    
        emit StrategyMigrated(address(oldStrategy), address(newStrategy));
    }

    function withdraw(uint256 assets, address receiver, address owner) public override nonReentrant returns (uint256) {
        return withdraw(assets, receiver, owner);
    }

    function redeem(uint256 shares, address receiver, address owner) public override nonReentrant returns (uint256) {
        return redeem(shares, receiver, owner);
    }
    function _withdraw( address caller, address receiver, address owner, uint256 assets, uint256 shares ) internal override {
        uint thisBalance = IERC20(asset()).balanceOf(address(this));
        if (thisBalance < assets){
            for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
                BaseStrategy strategy = withdrawQueue[i];
                uint needed = assets - thisBalance;

                if (address(strategy) == address(0)) {
                    break;
                }

                StrategyInfo storage info = strategyInfoMap[strategy];
                if (info.balance == 0) {
                    continue;
                }

                uint balanceBefore = info.balance;
                uint take = needed < balanceBefore ? needed : balanceBefore;

                info.balance -= strategy.pull(take);
                // проверки на измененный баланс
                require(info.balance >= balanceBefore - take, "incorrect withdraw");


                if (needed <= balanceBefore - info.balance) {
                    break;
                }
                needed -= (balanceBefore - info.balance);
            }
        }

        super._withdraw(caller, receiver, owner, assets, shares);
    }

    function report(BaseStrategy strategy) external onlyRole(KEEPER_ROLE) {
        _report(strategy);
    }

    function _report(BaseStrategy strategy) internal notPaused(strategy) {
        (uint256 profit, uint256 loss) = strategy.report();
        uint currentPerformanceFee = 0;
        uint currentManagementFee = 0;
        StrategyInfo storage info = strategyInfoMap[strategy];

        if (loss > 0) {
            if (info.balance < loss) {
                info.balance = 0;
            } else {
                info.balance -= loss;
            } 
        }

        if (profit > 0) {
            info.balance += profit;

            currentPerformanceFee = (profit * info.performanceFee) / BPS; 
            uint currentFee = currentPerformanceFee;

            if (_managementFee != 0) {
                uint time = block.timestamp - info.lastTakeTime;
                info.lastTakeTime = uint96(block.timestamp);

                currentManagementFee = (info.balance * _managementFee * time) / (BPS * SECONDS_PER_YEAR);

                currentFee += currentManagementFee;
            }

            if (currentFee > 0) {
                if (profit < currentFee) {
                    currentFee = profit;
                }
                _mint(_feeRecipient, previewDeposit(currentFee));
            }
        } 

        emit Reported(profit, loss, currentManagementFee, currentPerformanceFee);
    }

    function rebalance(BaseStrategy strategy) external onlyRole(KEEPER_ROLE) {
        _rebalance(strategy);
    }

    function _rebalance(BaseStrategy strategy) internal notPaused(strategy) {
        StrategyInfo storage info = strategyInfoMap[strategy];

        require(info.sharePercent >  0, "strategy not found");

        uint amount = totalAssets() * info.sharePercent / BPS;
        uint currentBalance = info.balance;
        
        if (currentBalance < amount) {
            uint toDeposit = amount - currentBalance;
            info.balance += toDeposit;

            IERC20(asset()).forceApprove(address(strategy), toDeposit);
            strategy.push(toDeposit);

        } else if (currentBalance > amount)  {
            uint toWithdraw = currentBalance - amount;

            info.balance -= strategy.pull(toWithdraw);

            require(info.balance >= currentBalance - toWithdraw, "incorrect withdraw");
        }

        emit UpdateStrategyInfo(strategy, amount);
    }

    function remove(BaseStrategy strategy) external onlyRole(DEFAULT_ADMIN_ROLE) returns(uint amountAssets){
        require (strategyInfoMap[strategy].sharePercent >  0, "strategy not exist");

        bool find = false;
        for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
            if (address(withdrawQueue[i]) == address(strategy)) {
                find = true;
            }
            if (find && i != MAXIMUM_STRATEGIES - 1) {
                withdrawQueue[i] = withdrawQueue[i + 1];
            }
        }
        withdrawQueue[MAXIMUM_STRATEGIES - 1] = BaseStrategy(address(0));
        require(find, "strategy not removed");

        delete strategyInfoMap[strategy];

        amountAssets = strategy.teakeAndClose();

        emit StrategyRemoved(address(strategy), amountAssets);
    }

    function setWithdrawalQueue(BaseStrategy[MAXIMUM_STRATEGIES] memory queue) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
            if (address(withdrawQueue[i]) == address(0)) {
                break;
            }

            BaseStrategy newPos = queue[i];

            require (address(newPos) != address(0), "Cannot use to remove");
            require (strategyInfoMap[newPos].sharePercent >  0, "Cannot use to change strategies");
        }

        withdrawQueue = queue;

        emit UpdateWithdrawalQueue(queue);
    }

    function setSharePercent(BaseStrategy strategy, uint16 sharePercent) public onlyRole(DEFAULT_ADMIN_ROLE) checkBorderBPS(sharePercent) {
        uint16 currentPercent = strategyInfoMap[strategy].sharePercent;
        uint totalSharePercent = 0;
        
        for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
            BaseStrategy currentStrategy = withdrawQueue[i];

            if(address(currentStrategy) == address(0)) {
                break;
            }

            totalSharePercent += strategyInfoMap[currentStrategy].sharePercent;
        }

        require(totalSharePercent - currentPercent + sharePercent <= MAX_PERSENT, "total share <= 100%");

        strategyInfoMap[strategy].sharePercent = sharePercent;

        emit UpdateStrategySharePercent(address(strategy), sharePercent);
    }

    function setPerformanceFee(BaseStrategy strategy, uint16 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) checkBorderBPS(newFee) {
        strategyInfoMap[strategy].performanceFee = newFee;

        emit UpdatePerformanceFee(address(strategy), newFee);
    }

    function setManagementFee(uint16 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) checkBorderBPS(newFee) {
        _managementFee = newFee;

        emit UpdateManagementFee(newFee);
    }

    function setFeeRecipient(address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(recipient != address(0), "zero address");
        _feeRecipient = recipient;

        emit UpdateManagementRecipient(recipient);
    }

    function emergencyWithdraw(BaseStrategy strategy) public onlyRole(DEFAULT_ADMIN_ROLE) returns(uint amount) {
        strategyInfoMap[strategy].balance = 0;
        amount = strategy.emergencyWithdraw();
    }

    function pause(BaseStrategy strategy) external onlyRole(KEEPER_ROLE) notPaused(strategy) {
        strategy.pause();
    }

    function unpause(BaseStrategy strategy) external onlyRole(KEEPER_ROLE) {
        require(strategy.isPaused(), "not paused");
        strategy.unpause();
    }

    function maxWithdraw(address owner) public view override returns (uint256) {
        uint256 totalAvailable = totalAssets();
        
        uint256 maxShares = balanceOf(owner);
        uint256 maxAssets = convertToAssets(maxShares);
        
        return maxAssets < totalAvailable ? maxAssets : totalAvailable;
    }

    function maxRedeem(address owner) public view override returns (uint256) {
        uint256 totalAvailable = totalAssets();
        
        uint256 maxShares = balanceOf(owner);
        uint256 sharesFromLiquidity = convertToShares(totalAvailable);
        
        return maxShares < sharesFromLiquidity ? maxShares : sharesFromLiquidity;
    }

    function withdrabalQueue() external view returns(BaseStrategy[MAXIMUM_STRATEGIES] memory) {
        return withdrawQueue;
    }
    
    function strategyPerformanceFee(BaseStrategy strategy) external view returns(uint16) {
        return strategyInfoMap[strategy].performanceFee;
    }

    function managementFee() external view returns(uint16) {
        return _managementFee;
    }

    function feeRecipient() external view returns(address) {
        return _feeRecipient;
    }

    function totalAssets() public view override returns (uint256) {
        uint256 vaultBalance = IERC20(asset()).balanceOf(address(this));

        for (uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
            BaseStrategy strategy = withdrawQueue[i];
            if (address(strategy) == address(0)) {
                break;
            }

            if (strategy.isPaused()) {
                continue;
            }

            vaultBalance += strategyInfoMap[withdrawQueue[i]].balance;
        }

        return vaultBalance;
    }

    function strategyBalance(BaseStrategy strategy) public view returns(uint) {
        return strategyInfoMap[strategy].balance;
    }

    function strategySharePercent(BaseStrategy strategy) external view returns(uint16) {
        return strategyInfoMap[strategy].sharePercent;
    }

    event UpdateManagementRecipient(address indexed recipient);
    
    event UpdateManagementFee(uint16 indexed fee);

    event UpdatePerformanceFee(address indexed strategy, uint16 indexed newFee);
    
    event UpdateStrategySharePercent(address indexed strategy, uint newPercent);

    event StrategyAdded (address indexed strategy);

    event UpdateStrategyInfo(BaseStrategy indexed strategy, uint newBalance);
    
    event UpdateWithdrawalQueue(BaseStrategy[MAXIMUM_STRATEGIES]);

    event StrategyMigrated (address indexed oldVersion, address indexed newVersion );

    event StrategyRemoved (address indexed strategy, uint totalAssets);
    
    event Reported(
        uint256 profit,
        uint256 loss,
        uint256 managementFees,
        uint256 performanceFees
    );
}