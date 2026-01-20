// SPDX-License-Identifier: MIT
// pragma solidity 0.8.33;
pragma solidity ^0.8.0;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {IBaseStrategy} from "./interfaces/IBaseStrategy.sol";
import {IVault} from "./interfaces/IVault.sol";

/**
 * @title Vault ERC-4626 with Strategy Support
 * @notice Extends the ERC-4626 standard to create a managed asset vault with a strategy system
 * @dev The contract allows adding strategies, managing asset allocation, and automatically charging fees
 */
contract Vault is IVault, ERC4626, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    /// @notice Basis for percentage calculations (100% = 10,000)
    uint256 internal constant BPS = 10_000;
    /// @notice Default performance fee (1%)
    uint16 internal constant DEFAULT_PERFORMANCE_FEE = 100;
    /// @notice Default management fee (1%)
    uint16 internal constant DEFAULT_MANAGEMENT_FEE = 100;
    /// @notice Maximum percentage (100%)
    uint16 internal constant MAX_PERCENT = 10_000;
    /// @notice Maximum number of strategies that can be added
    uint256 internal constant MAXIMUM_STRATEGIES = 20;
    /// @notice Minimum percentage (0.01%)
    uint16 internal constant MIN_PERCENT = 1;
    /// @notice Seconds per year for max profit unlocking time.
    /// @dev 365.2425 days
    uint256 internal constant SECONDS_PER_YEAR = 31_556_952; // 365.2425 days
    /// @notice emergency role
    bytes32 public constant EMERGENCY_ADMIN_ROLE = keccak256("EMERGENCY_ADMIN_ROLE");
    /// @notice Keeper role (bot/operator)
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    /// @notice Pauser role
    /// @notice can pause & unpause strategies
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    /// @notice The percent in basis points of profit that is charged as a fee.
    uint16 private _managementFee;
    /// @notice The address to pay the `performanceFee` to.
    address private _feeRecipient;
    /// @notice Withdrawal queue for strategies
    IBaseStrategy[MAXIMUM_STRATEGIES] private _withdrawalQueue;

    /**
     * @notice Strategy information structure
     * @param balance Current strategy balance in the vault
     * @param lastTakeTime Time of last management fee collection
     * @param sharePercent Percentage of total deposits allocated to the strategy
     * @param performanceFee Performance fee in basis points
     */
    struct StrategyInfo {
        uint256 balance;
        uint96 lastTakeTime;
        uint16 sharePercent;
        uint16 performanceFee; // The percent in basis points of profit that is charged as a fee.
    }
    /// @notice Mapping of strategy information
    mapping(IBaseStrategy => StrategyInfo) private _strategyInfoMap;

    /**
     * @notice Creates a new Vault contract
     * @dev Initializes an ERC-4626 vault with given parameters
     * @param assetToken_ Address of the underlying asset
     * @param nameShare_ Name of the share token
     * @param symbolShare_ Symbol of the share token
     * @param manager_ Manager (administrator) address
     * @param feeRecipient_ Fee recipient address
     * @custom:requires feeRecipient_ must not be zero address
     * @custom:requires assetToken_ must not be zero address
     * @custom:requires manager_ must not be zero address
     */
    constructor(
        IERC20 assetToken_,
        string memory nameShare_,
        string memory symbolShare_,
        address manager_,
        address feeRecipient_
    ) ERC4626(assetToken_) ERC20(nameShare_, symbolShare_) {
        require(feeRecipient_ != address(0), "feeRecipient zero address");
        require(address(assetToken_) != address(0), "assetToken zero address");
        require(manager_ != address(0), "manager zero address");

        _managementFee = DEFAULT_MANAGEMENT_FEE;
        _feeRecipient = feeRecipient_;

        _grantRole(DEFAULT_ADMIN_ROLE, manager_);
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, IERC165) returns (bool) {
        return interfaceId == type(IVault).interfaceId || interfaceId == type(IERC4626).interfaceId
            || interfaceId == type(IERC20).interfaceId || interfaceId == type(IERC20Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Internal function to check IBaseStrategy support
     * @param strategy Strategy to check
     */
    modifier supportIBaseStrategyInterface(IERC165 strategy) {
        _supportIBaseStrategyInterface(strategy);
        _;
    }

    /**
     * @notice Internal function to check IBaseStrategy support
     * @param strategy Strategy to check
     */
    function _supportIBaseStrategyInterface(IERC165 strategy) internal view {
        require(strategy.supportsInterface(type(IBaseStrategy).interfaceId), "unsupported IBaseStrategy");
    }

    /**
     * @notice Modifier to check if percentage is within bounds
     * @param num Percentage value
     */
    modifier checkBorderBps(uint16 num) {
        _checkBorderBps(num);
        _;
    }

    /**
     * @notice Internal function to check percentage bounds
     * @param num Percentage value
     */
    function _checkBorderBps(uint16 num) internal pure {
        require(num >= uint16(MIN_PERCENT), "min % is 0,01");
        require(num <= uint16(MAX_PERCENT), "max % is 100");
    }

    /**
     * @notice Modifier to check if strategy uses correct asset
     * @param strategy Strategy to check
     */
    modifier checkAsset(IBaseStrategy strategy) {
        _checkAsset(strategy);
        _;
    }

    /**
     * @notice Internal function to check asset compatibility
     * @param strategy Strategy to check
     */
    function _checkAsset(IBaseStrategy strategy) internal view {
        require(strategy.asset() == address(asset()), "bad strategy asset in");
    }

    /**
     * @notice Modifier to check if strategy references correct vault
     * @param strategy Strategy to check
     */
    modifier checkVault(IBaseStrategy strategy) {
        _checkVault(strategy);
        _;
    }

    /**
     * @notice Internal function to check vault reference
     * @param strategy Strategy to check
     */
    function _checkVault(IBaseStrategy strategy) internal view {
        require(strategy.vault() == address(this), "bad strategy vault in");
    }

    /**
     * @notice Modifier to check if strategy is not paused
     * @param strategy Strategy to check
     */
    modifier notPaused(IBaseStrategy strategy) {
        _notPaused(strategy);
        _;
    }

    /**
     * @notice Internal function to check pause status
     * @param strategy Strategy to check
     */
    function _notPaused(IBaseStrategy strategy) internal view {
        require(!strategy.isPaused(), "is paused");
    }

    /**
     * @inheritdoc IVault
     * @dev Strategy must be configured with correct assets and reference to this vault
     * @custom:modifier onlyRole(DEFAULT_ADMIN_ROLE) Only administrator
     * @custom:modifier supportIBaseStrategyInterface Strategy must implement IBaseStrategy
     * @custom:modifier checkAsset Strategy must use the same asset
     * @custom:modifier checkVault Strategy must reference this vault
     * @custom:requires Must have available slot for new strategy
     * @custom:requires Strategy must not already exist
     * @custom:requires Strategy allowance must be type(uint256).max
     * @custom:emits StrategyAdded
     */
    function add(IBaseStrategy newStrategy, uint16 sharePercent)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        supportIBaseStrategyInterface(IERC165(newStrategy))
        checkAsset(newStrategy)
        checkVault(newStrategy)
    {
        require(
            IERC20(asset()).allowance(address(newStrategy), address(this)) == type(uint256).max,
            "must allowance type(uint256).max"
        );
        require(address(_withdrawalQueue[MAXIMUM_STRATEGIES - 1]) == address(0), "limited of strategy");

        StrategyInfo storage info = _strategyInfoMap[newStrategy];

        require(info.sharePercent == 0, "strategy exist");

        for (uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
            if (address(_withdrawalQueue[i]) == address(0)) {
                _withdrawalQueue[i] = newStrategy;
                break;
            }
        }

        setSharePercent(newStrategy, sharePercent);
        info.lastTakeTime = uint96(block.timestamp);
        info.performanceFee = DEFAULT_PERFORMANCE_FEE;
        _grantRole(KEEPER_ROLE, address(newStrategy));

        emit StrategyAdded(address(newStrategy));
    }

    /**
     * @inheritdoc IVault
     * @dev Completely transfers balance and settings from old to new strategy
     * @custom:modifier onlyRole(DEFAULT_ADMIN_ROLE) Only administrator
     * @custom:modifier supportIBaseStrategyInterface Strategy must implement IBaseStrategy
     * @custom:modifier checkAsset New strategy must use the same asset
     * @custom:modifier checkVault New strategy must reference this vault
     * @custom:requires New strategy must not already exist
     * @custom:emits StrategyMigrated
     */
    function migrate(IBaseStrategy oldStrategy, IBaseStrategy newStrategy)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        supportIBaseStrategyInterface(IERC165(newStrategy))
        checkAsset(newStrategy)
        checkVault(newStrategy)
    {
        require(_strategyInfoMap[newStrategy].sharePercent == 0, "strategy already exist");
        StrategyInfo memory info = _strategyInfoMap[oldStrategy];

        delete _strategyInfoMap[oldStrategy];
        _revokeRole(KEEPER_ROLE, address(oldStrategy));

        for (uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
            if (address(_withdrawalQueue[i]) == address(oldStrategy)) {
                _withdrawalQueue[i] = newStrategy;
                _strategyInfoMap[newStrategy] = StrategyInfo({
                    balance: info.balance,
                    lastTakeTime: uint96(block.timestamp),
                    sharePercent: info.sharePercent,
                    performanceFee: info.performanceFee
                });
                _grantRole(KEEPER_ROLE, address(newStrategy));

                (uint256 profit, uint256 loss,) = _report(oldStrategy, false);

                uint256 balance = oldStrategy.pull(profit > 0 ? info.balance + profit : info.balance - loss);

                IERC20(asset()).forceApprove(address(newStrategy), balance);
                newStrategy.push(balance);
                break;
            }
        }

        emit StrategyMigrated(address(oldStrategy), address(newStrategy));
    }

    /**
     * @inheritdoc ERC4626
     * @custom:modifier nonReentrant Reentrancy protection
     */
    function withdraw(uint256 assets, address receiver, address owner)
        public
        override(ERC4626, IERC4626)
        nonReentrant
        returns (uint256)
    {
        return super.withdraw(assets, receiver, owner);
    }

    /**
     * @inheritdoc ERC4626
     * @custom:modifier nonReentrant Reentrancy protection
     */
    function redeem(uint256 shares, address receiver, address owner)
        public
        override(ERC4626, IERC4626)
        nonReentrant
        returns (uint256)
    {
        return super.redeem(shares, receiver, owner);
    }

    /**
     * @notice Internal withdrawal function
     * @param caller Address initiating withdrawal
     * @param receiver Address receiving assets
     * @param owner Address owning shares
     * @param assets Amount of assets to withdraw
     * @param shares Amount of shares to burn
     */
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        uint256 thisBalance = IERC20(asset()).balanceOf(address(this));
        if (thisBalance < assets) {
            uint256 needed = assets - thisBalance;
            for (uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
                IBaseStrategy strategy = _withdrawalQueue[i];

                StrategyInfo storage info = _strategyInfoMap[strategy];
                if (info.balance == 0) {
                    continue;
                }

                uint256 balanceBefore = info.balance;
                uint256 take = needed < balanceBefore ? needed : balanceBefore;

                info.balance -= strategy.pull(take);

                if (needed <= balanceBefore - info.balance) {
                    break;
                }
                needed -= (balanceBefore - info.balance);
            }
        }

        super._withdraw(caller, receiver, owner, assets, shares);
    }

    /**
     * @inheritdoc IVault
     * @dev Calculates profit/loss and charges fees
     * @custom:modifier onlyRole(KEEPER_ROLE) Only keeper
     * @custom:emits Reported
     */
    function report(IBaseStrategy strategy)
        external
        onlyRole(KEEPER_ROLE)
        returns (uint256 profit, uint256 loss, uint256 balance)
    {
        return _report(strategy, true);
    }

    /**
     * @notice Internal function to process strategy report
     * @param strategy Strategy to report on
     */
    function _report(IBaseStrategy strategy, bool update)
        internal
        notPaused(strategy)
        returns (uint256 profit, uint256 loss, uint256 balance)
    {
        (profit, loss) = strategy.report();
        uint256 currentPerformanceFee = 0;
        uint256 currentManagementFee = 0;
        StrategyInfo storage info = _strategyInfoMap[strategy];

        if (loss > 0 && update) {
            if (info.balance < loss) {
                info.balance = 0;
            } else {
                info.balance -= loss;
            }
        }

        if (profit > 0) {
            if (update) {
                info.balance += profit;
            }

            currentPerformanceFee = (profit * info.performanceFee) / BPS;
            uint256 currentFee = currentPerformanceFee;

            if (_managementFee != 0) {
                uint256 time = block.timestamp - info.lastTakeTime;
                if (update) {
                    info.lastTakeTime = uint96(block.timestamp);
                }
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
        balance = info.balance;

        emit Reported(profit, loss, currentManagementFee, currentPerformanceFee);
    }

    /**
     * @inheritdoc IVault
     * @dev Adjusts strategy balance to match its sharePercent
     * @custom:modifier onlyRole(KEEPER_ROLE) Only keeper
     * @custom:modifier notPaused Strategy must not be paused
     * @custom:requires Strategy must exist
     * @custom:emits UpdateStrategyInfo
     */
    function rebalance(IBaseStrategy strategy) external onlyRole(KEEPER_ROLE) {
        _rebalance(strategy);
    }

    /**
     * @notice Internal function to rebalance strategy
     * @param strategy Strategy to rebalance
     */
    function _rebalance(IBaseStrategy strategy) internal notPaused(strategy) {
        StrategyInfo storage info = _strategyInfoMap[strategy];

        require(info.sharePercent > 0, "strategy not found");

        uint256 amount = totalAssets() * info.sharePercent / BPS;
        uint256 currentBalance = info.balance;

        if (currentBalance < amount) {
            uint256 toDeposit = amount - currentBalance;
            info.balance += toDeposit;

            IERC20(asset()).forceApprove(address(strategy), toDeposit);
            strategy.push(toDeposit);
        } else if (currentBalance > amount) {
            uint256 toWithdraw = currentBalance - amount;

            info.balance -= strategy.pull(toWithdraw);
        }

        emit UpdateStrategyInfo(strategy, amount);
    }

    /**
     * @inheritdoc IVault
     * @dev Withdraws all assets from the strategy and removes it from the queue
     * @custom:modifier onlyRole(DEFAULT_ADMIN_ROLE) Only administrator
     * @custom:requires Strategy must exist
     * @custom:emits StrategyRemoved
     */
    function remove(IBaseStrategy strategy) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256 amountAssets) {
        require(_strategyInfoMap[strategy].sharePercent > 0, "strategy not exist");

        bool find = false;
        for (uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
            if (address(_withdrawalQueue[i]) == address(strategy)) {
                find = true;
            }
            if (find && i != MAXIMUM_STRATEGIES - 1) {
                _withdrawalQueue[i] = _withdrawalQueue[i + 1];
            }
        }
        _withdrawalQueue[MAXIMUM_STRATEGIES - 1] = IBaseStrategy(address(0));
        require(find, "strategy not removed");

        _revokeRole(KEEPER_ROLE, address(strategy));
        delete _strategyInfoMap[strategy];

        amountAssets = strategy.takeAndClose();

        emit StrategyRemoved(address(strategy), amountAssets);
    }

    /**
     * @inheritdoc IVault
     * @dev Defines the order in which strategies will be used for withdrawals
     * @custom:modifier onlyRole(DEFAULT_ADMIN_ROLE) Only administrator
     * @custom:requires All strategies in queue must exist
     * @custom:emits UpdateWithdrawalQueue
     */
    function setWithdrawalQueue(IBaseStrategy[MAXIMUM_STRATEGIES] memory queue) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
            if (address(_withdrawalQueue[i]) == address(0)) {
                break;
            }

            IBaseStrategy newPos = queue[i];

            require(address(newPos) != address(0), "Cannot use to remove");
            require(_strategyInfoMap[newPos].sharePercent > 0, "Cannot use to change strategies");
        }

        _withdrawalQueue = queue;

        emit UpdateWithdrawalQueue(queue);
    }

    /**
     * @inheritdoc IVault
     * @custom:modifier onlyRole(DEFAULT_ADMIN_ROLE) Only administrator
     * @custom:modifier checkBorderBps Percentage must be within valid bounds
     * @custom:requires Sum of all percentages must not exceed 100%
     * @custom:emits UpdateStrategySharePercent
     */
    function setSharePercent(IBaseStrategy strategy, uint16 sharePercent)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        checkBorderBps(sharePercent)
    {
        uint16 currentPercent = _strategyInfoMap[strategy].sharePercent;
        uint256 totalSharePercent = 0;

        for (uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
            IBaseStrategy currentStrategy = _withdrawalQueue[i];

            if (address(currentStrategy) == address(0)) {
                break;
            }

            totalSharePercent += _strategyInfoMap[currentStrategy].sharePercent;
        }

        require(totalSharePercent - currentPercent + sharePercent <= MAX_PERCENT, "total share <= 100%");

        _strategyInfoMap[strategy].sharePercent = sharePercent;

        emit UpdateStrategySharePercent(address(strategy), sharePercent);
    }

    /**
     * @inheritdoc IVault
     * @custom:modifier onlyRole(DEFAULT_ADMIN_ROLE) Only administrator
     * @custom:modifier checkBorderBps Fee must be within valid bounds
     * @custom:emits UpdatePerformanceFee
     */
    function setPerformanceFee(IBaseStrategy strategy, uint16 newFee)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        checkBorderBps(newFee)
    {
        _strategyInfoMap[strategy].performanceFee = newFee;

        emit UpdatePerformanceFee(address(strategy), newFee);
    }

    /**
     * @inheritdoc IVault
     * @custom:modifier onlyRole(DEFAULT_ADMIN_ROLE) Only administrator
     * @custom:modifier checkBorderBps Fee must be within valid bounds
     * @custom:emits UpdateManagementFee
     */
    function setManagementFee(uint16 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) checkBorderBps(newFee) {
        _managementFee = newFee;

        emit UpdateManagementFee(newFee);
    }

    /**
     * @inheritdoc IVault
     * @custom:modifier onlyRole(DEFAULT_ADMIN_ROLE) Only administrator
     * @custom:requires recipient must not be zero address
     * @custom:emits UpdateManagementRecipient
     */
    function setFeeRecipient(address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(recipient != address(0), "zero address");
        _feeRecipient = recipient;

        emit UpdateManagementRecipient(recipient);
    }

    /**
     * @inheritdoc IVault
     * @dev Used in case of strategy issues
     * @custom:modifier onlyRole(EMERGENCY_ADMIN_ROLE) Only emergency administrator
     * @custom:emits EmergencyWithdraw (in strategy)
     */
    function emergencyWithdraw(IBaseStrategy strategy) public onlyRole(EMERGENCY_ADMIN_ROLE) returns (uint256 amount) {
        _strategyInfoMap[strategy].balance = 0;
        amount = strategy.emergencyWithdraw();
    }

    /**
     * @inheritdoc IVault
     * @custom:modifier onlyRole(PAUSER_ROLE) Only pauser manager
     * @custom:modifier notPaused Strategy must not already be paused
     */
    function pause(IBaseStrategy strategy) external onlyRole(PAUSER_ROLE) notPaused(strategy) {
        strategy.pause();
    }

    /**
     * @inheritdoc IVault
     * @custom:modifier onlyRole(PAUSER_ROLE) Only pauser manager
     * @custom:requires Strategy must be paused
     */
    function unpause(IBaseStrategy strategy) external onlyRole(PAUSER_ROLE) {
        require(strategy.isPaused(), "not paused");
        strategy.unpause();
    }

    /**
     * @inheritdoc IVault
     */
    function strategyGrantRole(IBaseStrategy strategy, bytes32 role, address account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (account == address(this)) return;
        strategy.grantRole(role, account);
    }

    /**
     * @inheritdoc IVault
     */
    function strategyRevokeRole(IBaseStrategy strategy, bytes32 role, address account)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (account == address(this)) return;
        strategy.revokeRole(role, account);
    }

    /**
     * @inheritdoc ERC4626
     * @dev Takes into account liquidity in vault and strategies
     */
    function maxWithdraw(address owner) public view override(ERC4626, IVault) returns (uint256) {
        uint256 totalAvailable = totalAssets();

        uint256 maxShares = balanceOf(owner);
        uint256 maxAssets = convertToAssets(maxShares);

        return maxAssets < totalAvailable ? maxAssets : totalAvailable;
    }

    /**
     * @inheritdoc ERC4626
     * @dev Takes into account liquidity in vault and strategies
     */
    function maxRedeem(address owner) public view override(ERC4626, IVault) returns (uint256) {
        uint256 totalAvailable = totalAssets();

        uint256 maxShares = balanceOf(owner);
        uint256 sharesFromLiquidity = convertToShares(totalAvailable);

        return maxShares < sharesFromLiquidity ? maxShares : sharesFromLiquidity;
    }

    /**
     * @notice Gets withdrawal queue
     * @return Queue of strategies for withdrawals
     */
    function withdrawalQueue() external view returns (IBaseStrategy[MAXIMUM_STRATEGIES] memory) {
        return _withdrawalQueue;
    }

    /**
     * @notice Gets strategy performance fee
     * @param strategy Strategy
     * @return Fee in basis points
     */
    function strategyPerformanceFee(IBaseStrategy strategy) external view returns (uint16) {
        return _strategyInfoMap[strategy].performanceFee;
    }

    /**
     * @notice Gets vault management fee
     * @return Fee in basis points
     */
    function managementFee() external view returns (uint16) {
        return _managementFee;
    }

    /**
     * @notice Gets fee recipient address
     * @return Recipient address
     */
    function feeRecipient() external view returns (address) {
        return _feeRecipient;
    }

    /**
     * @inheritdoc ERC4626
     * @dev Includes balance in vault itself and all active strategies
     */
    function totalAssets() public view override(ERC4626, IVault) returns (uint256) {
        uint256 vaultBalance = IERC20(asset()).balanceOf(address(this));

        for (uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
            IBaseStrategy strategy = _withdrawalQueue[i];
            if (address(strategy) == address(0)) {
                break;
            }

            if (strategy.isPaused()) {
                continue;
            }

            vaultBalance += _strategyInfoMap[_withdrawalQueue[i]].balance;
        }

        return vaultBalance;
    }

    /**
     * @notice Gets strategy balance
     * @param strategy Strategy
     * @return Strategy balance in the vault
     */
    function strategyBalance(IBaseStrategy strategy) public view returns (uint256) {
        return _strategyInfoMap[strategy].balance;
    }

    /**
     * @notice Gets strategy allocation percentage
     * @param strategy Strategy
     * @return Allocation percentage in basis points
     */
    function strategySharePercent(IBaseStrategy strategy) external view returns (uint16) {
        return _strategyInfoMap[strategy].sharePercent;
    }
}
