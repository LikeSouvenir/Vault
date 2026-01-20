// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Pool Interface
 * @notice Interface for interacting with Aave lending pool or similar DeFi protocol
 * @dev Provides core functions for supplying and withdrawing assets from liquidity pools
 */
interface IPool {
    /**
     * @notice Supplies assets to the pool on behalf of a user
     * @dev Deposits tokens into the lending pool and mints aTokens in return
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount of tokens to supply
     * @param onBehalfOf The address that will receive the aTokens
     * @param referralCode Referral code used for tracking (0 for no referral)
     */
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /**
     * @notice Withdraws assets from the pool
     * @dev Burns aTokens and returns the underlying asset to the specified address
     * @param asset The address of the underlying asset to withdraw
     * @param amount The amount of tokens to withdraw (max uint256 for entire balance)
     * @param to The address that will receive the withdrawn tokens
     * @return The actual amount withdrawn
     */
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

/**
 * @title Rewards Controller Interface
 * @notice Interface for managing reward distribution in lending protocols
 * @dev Handles claiming and querying of incentive rewards (e.g., Aave's liquidity mining rewards)
 */
interface IRewardsController {
    /**
     * @notice Claims accumulated rewards for specified assets
     * @dev Transfers earned rewards to the beneficiary address
     * @param assets Array of asset addresses for which to claim rewards
     * @param amount The amount of rewards to claim (max uint256 for all available)
     * @param to The address that will receive the claimed rewards
     * @param reward The address of the reward token to claim
     * @return The amount of rewards actually claimed
     */
    function claimRewards(address[] calldata assets, uint256 amount, address to, address reward)
        external
        returns (uint256);

    /**
     * @notice Queries unclaimed rewards for a user
     * @dev Returns the accumulated but unclaimed reward amount for specific assets
     * @param assets Array of asset addresses to check for rewards
     * @param user The address of the user to query
     * @param reward The address of the reward token to check
     * @return The amount of unclaimed rewards available
     */
    function getUserRewards(address[] calldata assets, address user, address reward) external view returns (uint256);
}

/**
 * @title aToken Interface
 * @notice Interface for Aave's interest-bearing tokens
 * @dev ERC20 tokens that represent a deposit in the lending pool and accrue interest over time
 */
interface IAToken is IERC20 {
    /**
     * @notice Returns the address of the underlying asset
     * @dev This token represents a wrapped version of the underlying asset
     * @return The address of the underlying ERC20 token
     */
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}
