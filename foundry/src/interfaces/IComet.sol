// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Compound V3 (Comet) Core Interface
 * @notice Interface for interacting with Compound V3 lending protocol
 * @dev Main Comet protocol contract that handles supply, withdraw, and rate calculations
 */
interface IComet {
    /**
     * @notice Gets the balance of an account in base token units
     * @dev Returns the amount of base tokens that would be received if withdrawing all supplied assets
     * @param account The address of the account to query
     * @return The balance of the account in base token units
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice Supplies an asset to the protocol
     * @dev Transfers asset from caller and credits account's balance
     * @param asset The address of the asset to supply
     * @param amount The amount of the asset to supply
     */
    function supply(address asset, uint256 amount) external;

    /**
     * @notice Withdraws an asset from the protocol
     * @dev Debits account's balance and transfers asset to caller
     * @param asset The address of the asset to withdraw
     * @param amount The amount of the asset to withdraw
     */
    function withdraw(address asset, uint256 amount) external;

    /**
     * @notice Gets the address of the base token for this market
     * @dev Base token is the primary asset (e.g., USDC for USDC market)
     * @return The address of the base token
     */
    function baseToken() external view returns (address);

    /**
     * @notice Calculates the current supply rate based on utilization
     * @dev Rate is returned as a per-second interest rate scaled by 1e18
     * @param utilization The current utilization rate (0 to 1e18 scale)
     * @return The supply rate per second (scaled by 1e18)
     */
    function getSupplyRate(uint256 utilization) external view returns (uint64);

    /**
     * @notice Calculates the current borrow rate based on utilization
     * @dev Rate is returned as a per-second interest rate scaled by 1e18
     * @param utilization The current utilization rate (0 to 1e18 scale)
     * @return The borrow rate per second (scaled by 1e18)
     */
    function getBorrowRate(uint256 utilization) external view returns (uint64);

    /**
     * @notice Gets the total amount of assets supplied to the protocol
     * @dev Returns total supply across all users in base token units
     * @return The total supply amount in base token units
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the total amount of assets borrowed from the protocol
     * @dev Returns total borrow across all users in base token units
     * @return The total borrow amount in base token units
     */
    function totalBorrow() external view returns (uint256);

    /**
     * @notice Checks if a manager has permission to act on behalf of an owner
     * @dev Used for delegated account management
     * @param owner The address of the account owner
     * @param manager The address being checked for permissions
     * @return True if manager has permission, false otherwise
     */
    function hasPermission(address owner, address manager) external view returns (bool);
}

/**
 * @title Compound V3 Rewards Interface
 * @notice Interface for claiming rewards in Compound V3 protocol
 * @dev Handles COMP token rewards distribution for suppliers and borrowers
 */
interface ICometRewards {
    /**
     * @notice Claims accrued rewards for an account
     * @dev Transfers COMP rewards to the account based on their activity
     * @param comet The address of the Comet market
     * @param account The address of the account to claim rewards for
     * @param shouldAccrue Whether to accrue interest before claiming
     */
    function claim(address comet, address account, bool shouldAccrue) external;

    /**
     * @notice Gets the amount of rewards owed to an account
     * @dev Calculates unclaimed COMP rewards for a specific account
     * @param comet The address of the Comet market
     * @param account The address of the account to check
     * @return The amount of COMP rewards owed to the account
     */
    function getRewardOwed(address comet, address account) external returns (uint256);
}
