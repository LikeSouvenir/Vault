// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IBaseStrategy - Interface for Base Strategy Contract
 * @notice Defines the interface for asset management strategies
 */
interface IBaseStrategy {
    /**
     * @notice Report and reinvest
     */
    function reportAndInvest() external;

    /**
     * @notice Deposit assets into strategy
     * @param amount Amount of assets to deposit
     */
    function push(uint256 amount) external;

    /**
     * @notice Withdraw assets from strategy
     * @param amount Amount of assets to withdraw
     * @return value Actual amount withdrawn
     */
    function pull(uint256 amount) external returns (uint256 value);

    /**
     * @notice Report on strategy performance
     * @return profit Profit since last report
     * @return loss Loss since last report
     */
    function report() external returns (uint256 profit, uint256 loss);

    /**
     * @notice Withdraw all assets and close strategy
     * @return amount Amount of assets withdrawn
     */
    function takeAndClose() external returns (uint256 amount);

    /**
     * @notice Emergency withdraw all assets
     * @return amount Amount of assets withdrawn
     */
    function emergencyWithdraw() external returns (uint256 amount);

    /**
     * @notice Pause strategy operation
     */
    function pause() external;

    /**
     * @notice Resume strategy operation
     */
    function unpause() external;

    /**
     * @notice Check if strategy is paused
     * @return true if strategy is paused
     */
    function isPaused() external view returns (bool);

    /**
     * @notice Get underlying asset address
     * @return Asset address
     */
    function asset() external view returns (address);

    /**
     * @notice Get vault address
     * @return Vault address
     */
    function vault() external view returns (address);

    /**
     * @notice Get last recorded balance
     * @return Asset balance
     */
    function lastTotalAssets() external view returns (uint256);

    /**
     * @notice Get strategy name
     * @return Strategy name
     */
    function name() external view returns (string memory);

    /**
     * @notice Event emitted when strategy is paused
     * @param timestamp Block timestamp
     */
    event StrategyPaused(uint256 indexed timestamp);

    /**
     * @notice Event emitted when strategy is unpaused
     * @param timestamp Block timestamp
     */
    event StrategyUnpaused(uint256 indexed timestamp);

    /**
     * @notice Event emitted when assets are pulled from strategy
     * @param assetPull Amount of assets pulled
     */
    event Pull(uint256 assetPull);

    /**
     * @notice Event emitted when assets are pushed to strategy
     * @param assetPush Amount of assets pushed
     */
    event Push(uint256 assetPush);

    /**
     * @notice Event emitted when strategy report is generated
     * @param time Block timestamp
     * @param profit Profit amount
     * @param loss Loss amount
     */
    event Report(uint256 indexed time, uint256 indexed profit, uint256 indexed loss);

    /**
     * @notice Event emitted on emergency withdrawal
     * @param timestamp Block timestamp
     * @param amount Amount withdrawn
     */
    event EmergencyWithdraw(uint256 timestamp, uint256 amount);
}
