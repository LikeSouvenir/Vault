// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Vault/AssetERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IFeeConfig} from "./interfaces/IFeeConfig.sol";
import {BaseStrategy} from "./BaseStrategy.sol";
/**
    Access Control
    функция присваивания роли БОТу

    ограничить ребалансировку и отчет бота 
    отдельный emergency admin
 */

contract Vault is ERC4626, AccessControl, ReentrancyGuard {
    uint internal constant BPS = 10_000;
    uint internal constant MAXIMUM_STRATEGIES = 20;
    uint16 internal constant DEFAULT_PERFORMANCE_FEE = 100;

    /// @notice Seconds per year for max profit unlocking time.
    uint256 internal constant SECONDS_PER_YEAR = 31_556_952; // 365.2425 days
    uint internal constant TWELVE_MONTHS = 12;
    uint internal constant ONE_MONTH = SECONDS_PER_YEAR / TWELVE_MONTHS;

    uint16 _managementFee; // The percent in basis points of profit that is charged as a fee.
    address _feeRecipient; // The address to pay the `performanceFee` to.
    BaseStrategy[MAXIMUM_STRATEGIES] withdrawQueue;

    bytes32 constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    struct StrategyBalance {
        uint balance;
        uint96 lastTakeTime;
        uint16 sharePercent;
        uint16 performanceFee;// The percent in basis points of profit that is charged as a fee.
    }
    mapping (BaseStrategy => StrategyBalance) strategyBalanceMap;

//
    constructor(IERC20 assetToken_, string memory nameShare_, string memory sybolShare_, address manager_, address feeRecipient_) 
        ERC4626(assetToken_) 
        ERC20(nameShare_, sybolShare_) 
    {
        _grantRole(DEFAULT_ADMIN_ROLE, manager_);
        _feeRecipient = feeRecipient_;
    }

    modifier checkBorderBPS(uint16 num) {
        require(num >= uint16(1), "min % is 0,01");
        require(num <= uint16(10_000), "max % is 100");
        _;
    }

    modifier strategyExist(BaseStrategy strategy) {
        require (strategyBalanceMap[strategy].sharePercent != 0, "strategy not exist");
        _;
    }

    modifier checkAsset(BaseStrategy strategy) {
        require (strategy.asset() == address(asset()), "bad strategy asset in");
        _;
    }

    modifier checkVault(BaseStrategy strategy) {
        require (strategy.vault() == address(this), "bad strategy vault in");
        _;
    }

    modifier notPaused(BaseStrategy strategy) {
        require(strategy.isPaused() == false, "is paused");
        _;
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
        require (ERC20(asset()).allowance(address(newStrategy), address(this)) == type(uint256).max, "must allowance type(uint256).max");
        require (address(withdrawQueue[MAXIMUM_STRATEGIES - 1]) != address(0), "limited of strategy");

        StrategyBalance storage info = strategyBalanceMap[newStrategy];

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
        require (strategyBalanceMap[newStrategy].sharePercent == 0, "strategy alredy exist");

        for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
            if (withdrawQueue[i] == oldStrategy) {
                StrategyBalance memory info = strategyBalanceMap[oldStrategy];
        
                withdrawQueue[i] = newStrategy;

                report(oldStrategy);
                uint balance = oldStrategy.pull(info.balance);

                newStrategy.push(balance);
                
                strategyBalanceMap[newStrategy] = StrategyBalance(
                    balance,
                    uint96(block.timestamp),
                    info.sharePercent,
                    info.performanceFee
                );

                delete strategyBalanceMap[oldStrategy];
                break;
            }
        }
    
        emit StrategyMigrated(address(oldStrategy), address(newStrategy));
    }

    function _withdraw( address caller, address receiver, address owner, uint256 assets, uint256 shares ) internal override {
        uint thisBalance = IERC20(asset()).balanceOf(address(this));
        if (thisBalance < assets){
            uint needed = assets - thisBalance;

            for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
                BaseStrategy currentStrategy = withdrawQueue[i];
                if (address(currentStrategy) == address(0)) {
                    break;
                }

                if (currentStrategy.isPaused()) {
                    continue;
                }

                StrategyBalance storage info = strategyBalanceMap[currentStrategy];
                if (info.balance == 0) {
                    continue;
                }
            
                uint result = currentStrategy.pull(needed < info.balance ? needed : info.balance);

                info.balance -= result;
                needed -= result;
                if (needed == 0) {
                    break;
                } 
            }
            
            require(needed == 0, "not enaugth");
        }

        super._withdraw(caller, receiver, owner, assets, shares);
    }

    function _calculateTotalAvailable(BaseStrategy strategy) internal {

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
    
    function reportsAndInvests() external nonReentrant onlyRole(KEEPER_ROLE) {
        for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
            BaseStrategy strategy = withdrawQueue[i];

            if(address(strategy) == address(0)) {
                break;
            }

            if (strategy.isPaused()) {
                continue;
            }

            _report(strategy);
        }

        for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
            BaseStrategy strategy = withdrawQueue[i];

            if(address(strategy) == address(0)) {
                break;
            }

            if (strategy.isPaused()) {
                continue;
            }

            rebalance(strategy);
        }
    }

    function report(BaseStrategy strategy) public nonReentrant onlyRole(KEEPER_ROLE) {
        _report(strategy);
    }
    
    function _report(BaseStrategy strategy) internal notPaused(strategy) {
        StrategyBalance storage info = strategyBalanceMap[strategy];

        (uint256 profit, uint256 loss) = strategy.report();
        uint currentPerformanceFee;
        uint currentManagementFee;

        if (profit > 0) {
            info.balance += profit;

            currentPerformanceFee = (profit * info.performanceFee) / BPS;
            uint currentFee = currentPerformanceFee;

            if (_managementFee != 0) {
                uint monthsPassed = (block.timestamp - info.lastTakeTime) / ONE_MONTH;

                if (monthsPassed > 0) {
                    // Комиссия за каждый прошедший месяц
                    currentManagementFee = (info.balance * _managementFee) / BPS / TWELVE_MONTHS;

                    info.lastTakeTime = uint96(block.timestamp);
                    currentFee += currentManagementFee * monthsPassed;
                }
            }

            if (currentFee > 0) {
                if (profit < currentFee) {
                    currentFee = profit;
                }
                // _deposit(address(this), _feeRecipient, currentFee, previewDeposit(currentFee));
                _mint(_feeRecipient, previewDeposit(currentFee));
            }
        } else {
            info.balance -= loss;
        }

        emit Reported(profit, loss, currentManagementFee, currentPerformanceFee);
    }

    function rebalance(BaseStrategy strategy) public nonReentrant onlyRole(KEEPER_ROLE) notPaused(strategy) returns(uint amount) {
        StrategyBalance storage info = strategyBalanceMap[strategy];

        require(info.sharePercent != 0, "strategy not found");

        amount = totalAssets() * info.sharePercent / BPS;
        
        if (info.balance < amount) {
            strategy.push(amount - info.balance);

        } else if (info.balance > amount)  {
            strategy.pull(info.balance - amount);
        }
        
        info.balance = amount;

        emit UpdateStrategyBalance(strategy, amount);
    }

    function remove(BaseStrategy strategy) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant strategyExist(strategy) returns(uint amountAssets){
        bool find;
        for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
            if (withdrawQueue[i] == strategy) {
                report(strategy);

                amountAssets = strategy.pull(strategyBalanceMap[strategy].balance);
                
                delete strategyBalanceMap[strategy];
                find = true;
            }
            if (find && i != MAXIMUM_STRATEGIES - 1) {
                withdrawQueue[i] = withdrawQueue[i + 1];
            }
        }

        require(find, "strategy not removed");

        emit StrategyRemoved(address(strategy), amountAssets);
    }

    function setWithdrawalQueue(BaseStrategy[MAXIMUM_STRATEGIES] memory queue) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
            if (address(withdrawQueue[i]) == address(0)) {
                break;
            }

            BaseStrategy newPos = queue[i];

            require (address(newPos) != address(0), "Cannot use to remove");
            require (strategyBalanceMap[newPos].sharePercent != 0, "Incorrect address");
        }

        withdrawQueue = queue;

        emit UpdateWithdrawalQueue(queue);
    }

    function setSharePercent(BaseStrategy strategy, uint16 sharePercent) public onlyRole(DEFAULT_ADMIN_ROLE) checkBorderBPS(sharePercent) {
        uint16 currentPercent = strategyBalanceMap[strategy].sharePercent;
        uint totalSharePercent;
        
        for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
            BaseStrategy currentStrategy = withdrawQueue[i];

            if(address(currentStrategy) == address(0)) {
                break;
            }

            totalSharePercent += strategyBalanceMap[currentStrategy].sharePercent;
        }

        require(totalSharePercent - currentPercent + sharePercent <= 10000, "total share <= 100%");

        strategyBalanceMap[strategy].sharePercent = sharePercent;

        emit UpdateStrategySharePercent(address(strategy), sharePercent);
    }

    function setPerformanceFee(BaseStrategy strategy, uint16 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) checkBorderBPS(newFee) {
        strategyBalanceMap[strategy].performanceFee = newFee;

        emit UpdatePerformanceFee(address(strategy), newFee);
    }

    function setManagementFee(uint16 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) checkBorderBPS(newFee) {
        _managementFee = newFee;

        emit UpdateManagementFee(newFee);
    }

    function setFeeRecipient(address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(recipient >= address(0), "zero address");
        _feeRecipient = recipient;

        emit UpdateManagementRecipient(recipient);
    }

    function emergencyWithdraw(BaseStrategy strategy) public onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant returns(uint _amount) {
        report(strategy);
        if (strategy.isPaused()) {
            SafeERC20.safeTransferFrom(
                ERC20(asset()), 
                address(strategy), 
                address(this), 
                ERC20(asset()).balanceOf(address(strategy))
            );
        } else {
            _report(strategy);
            _amount = strategy.pull(strategyBalanceMap[strategy].balance);
            pause(strategy);
        }

        emit EmergencyWithdraw(block.timestamp, _amount);
    }

    function pause(BaseStrategy strategy) public onlyRole(KEEPER_ROLE) notPaused(strategy) {
        strategy.pause();
    }

    function unpause(BaseStrategy strategy) external onlyRole(KEEPER_ROLE) {
        require(strategy.isPaused(), "not paused");
        strategy.unpause();
    }

    function withdrabalQueue() external view returns(BaseStrategy[MAXIMUM_STRATEGIES] memory) {
        return withdrawQueue;
    }

    function strategyPersent(BaseStrategy strategy) external view returns(uint16 sharePercent) {
        return strategyBalanceMap[strategy].sharePercent;
    }

    function performanceFee(BaseStrategy strategy) external view returns(uint16) {
        return strategyBalanceMap[strategy].performanceFee;
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

            vaultBalance += strategyBalanceMap[withdrawQueue[i]].balance;
        }

        return vaultBalance;
    }

    function strategyBalance(BaseStrategy strategy) public view returns(uint) {
        return strategyBalanceMap[strategy].balance;
    }

    function strategySharePercent(BaseStrategy strategy) external view returns(uint16) {
        return strategyBalanceMap[strategy].sharePercent;
    }

    event UpdateManagementRecipient(address indexed recipient);
    
    event UpdateManagementFee(uint16 indexed fee);

    event UpdatePerformanceFee(address indexed strategy, uint16 indexed newFee);
    
    event UpdateStrategySharePercent(address indexed strategy, uint newPercent);

    event StrategyAdded (address indexed strategy);

    event UpdateStrategyBalance(BaseStrategy indexed strategy, uint newBalance);
    
    event UpdateWithdrawalQueue(BaseStrategy[MAXIMUM_STRATEGIES]);

    event StrategyMigrated (address indexed oldVersion, address indexed newVersion );

    event StrategyRemoved (address indexed strategy, uint totalAssets);
    
    event EmergencyWithdraw(uint timestamp, uint amount);

    event Reported(
        uint256 profit,
        uint256 loss,
        uint256 managementFees,
        uint256 performanceFees
    );
}