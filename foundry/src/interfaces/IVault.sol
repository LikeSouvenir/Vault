// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IBaseStrategy} from "./IBaseStrategy.sol";

uint256 constant MAXIMUM_STRATEGIES = 20;

/**
 * @title IVault - Interface for Vault Contract
 * @notice IERC-4626 compliant vault with strategy management capabilities
 */
interface IVault is IERC4626 {
    /**
     * @notice Adds a new strategy to the vault
     * @param newStrategy Address of the new strategy
     * @param sharePercent Asset allocation percentage for the strategy
     */
    function add(IBaseStrategy newStrategy, uint16 sharePercent) external;

    /**
     * @notice Migrates assets from old strategy to new strategy
     * @param oldStrategy Old strategy to migrate from
     * @param newStrategy New strategy to migrate to
     */
    function migrate(IBaseStrategy oldStrategy, IBaseStrategy newStrategy) external;

    /**
     * @notice Reports on strategy performance (called by keeper)
     * @param strategy Strategy to report on
     * @return profit Amount of strategy profit
     * @return loss Amount of strategy loss
     * @return balance current balance
     */
    function report(IBaseStrategy strategy) external returns (uint256 profit, uint256 loss, uint256 balance);

    /**
     * @notice Rebalances a strategy (called by keeper)
     * @param strategy Strategy to rebalance
     */
    function rebalance(IBaseStrategy strategy) external;

    /**
     * @notice Removes a strategy from the vault
     * @param strategy Strategy to remove
     * @return amountAssets Amount of assets withdrawn
     */
    function remove(IBaseStrategy strategy) external returns (uint256 amountAssets);

    /**
     * @notice Sets the withdrawal queue
     * @param queue New strategy queue
     */
    function setWithdrawalQueue(IBaseStrategy[MAXIMUM_STRATEGIES] memory queue) external;

    /**
     * @notice Sets allocation percentage for a strategy
     * @param strategy Strategy
     * @param sharePercent New allocation percentage
     */
    function setSharePercent(IBaseStrategy strategy, uint16 sharePercent) external;

    /**
     * @notice Sets performance fee for a strategy
     * @param strategy Strategy
     * @param newFee New fee in basis points
     */
    function setPerformanceFee(IBaseStrategy strategy, uint16 newFee) external;

    /**
     * @notice Sets management fee for the entire vault
     * @param newFee New fee in basis points
     */
    function setManagementFee(uint16 newFee) external;

    /**
     * @notice Sets fee recipient address
     * @param recipient New recipient address
     */
    function setFeeRecipient(address recipient) external;

    /**
     * @notice Emergency withdraw from strategy (admin only)
     * @param strategy Strategy for emergency withdrawal
     * @return amount Amount of assets withdrawn
     */
    function emergencyWithdraw(IBaseStrategy strategy) external returns (uint256 amount);

    /**
     * @notice Pauses a strategy
     * @param strategy Strategy to pause
     */
    function pause(IBaseStrategy strategy) external;

    /**
     * @notice Unpauses a strategy
     * @param strategy Strategy
     */
    function unpause(IBaseStrategy strategy) external;

    /**
     * @notice Gets withdrawal queue
     * @return Queue of strategies for withdrawals
     */
    function withdrawalQueue() external view returns (IBaseStrategy[MAXIMUM_STRATEGIES] memory);

    /**
     * @notice Gets strategy performance fee
     * @param strategy Strategy
     * @return Fee in basis points
     */
    function strategyPerformanceFee(IBaseStrategy strategy) external view returns (uint16);

    /**
     * @notice Gets vault management fee
     * @return Fee in basis points
     */
    function managementFee() external view returns (uint16);

    /**
     * @notice Gets fee recipient address
     * @return Recipient address
     */
    function feeRecipient() external view returns (address);

    /**
     * @notice Gets strategy balance
     * @param strategy Strategy
     * @return Strategy balance in the vault
     */
    function strategyBalance(IBaseStrategy strategy) external view returns (uint256);

    /**
     * @notice Gets strategy allocation percentage
     * @param strategy Strategy
     * @return Allocation percentage in basis points
     */
    function strategySharePercent(IBaseStrategy strategy) external view returns (uint16);

    /**
     * @notice Maximum amount of assets that can be withdrawn by owner
     * @param owner Owner of share tokens
     * @return Maximum amount of assets that can be withdrawn
     */
    function maxWithdraw(address owner) external view override returns (uint256);

    /**
     * @notice Maximum amount of shares that can be redeemed by owner
     * @param owner Owner of share tokens
     * @return Maximum amount of shares that can be redeemed
     */
    function maxRedeem(address owner) external view override returns (uint256);

    /**
     * @notice Calculates total assets in the vault
     * @return Total amount of assets
     */
    function totalAssets() external view override returns (uint256);

    /**
     * @notice Event emitted when strategy is added
     * @param strategy Address of the strategy
     */
    event StrategyAdded(address indexed strategy);

    /**
     * @notice Event emitted when strategy is migrated
     * @param oldVersion Address of the old strategy
     * @param newVersion Address of the new strategy
     */
    event StrategyMigrated(address indexed oldVersion, address indexed newVersion);

    /**
     * @notice Event emitted when strategy is removed
     * @param strategy Address of the strategy
     * @param totalAssets Amount of assets withdrawn
     */
    event StrategyRemoved(address indexed strategy, uint256 totalAssets);

    /**
     * @notice Event emitted when withdrawal queue is updated
     * @param queue New withdrawal queue
     */
    event UpdateWithdrawalQueue(IBaseStrategy[MAXIMUM_STRATEGIES] queue);

    /**
     * @notice Event emitted when strategy share percentage is updated
     * @param strategy Address of the strategy
     * @param newPercent New allocation percentage
     */
    event UpdateStrategySharePercent(address indexed strategy, uint256 newPercent);

    /**
     * @notice Event emitted when strategy performance fee is updated
     * @param strategy Address of the strategy
     * @param newFee New performance fee
     */
    event UpdatePerformanceFee(address indexed strategy, uint16 indexed newFee);

    /**
     * @notice Event emitted when management fee is updated
     * @param fee New management fee
     */
    event UpdateManagementFee(uint16 indexed fee);

    /**
     * @notice Event emitted when fee recipient is updated
     * @param recipient New fee recipient address
     */
    event UpdateManagementRecipient(address indexed recipient);

    /**
     * @notice Event emitted when strategy info is updated
     * @param strategy Strategy address
     * @param newBalance New strategy balance
     */
    event UpdateStrategyInfo(IBaseStrategy indexed strategy, uint256 newBalance);

    /**
     * @notice Event emitted when strategy report is generated
     * @param profit Profit amount
     * @param loss Loss amount
     * @param managementFees Management fees charged
     * @param performanceFees Performance fees charged
     */
    event Reported(uint256 profit, uint256 loss, uint256 managementFees, uint256 performanceFees);
}
