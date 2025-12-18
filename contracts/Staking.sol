// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking {
    IERC20 public immutable want;
    
    struct Stake {
        uint256 amount; // Amount of tokens staked
        uint256 timestamp; // Timestamp of when the staking started
    }

    mapping(address => Stake) public stakes;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);

    constructor(address tokenAddress) {
        want = IERC20(tokenAddress);
    }

    /// @notice Stake a specific amount of want tokens
    /// @param amount The amount of tokens to stake
    function deposite(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        // Transfer want tokens from the sender to the staking contract
        require(
            want.transferFrom(msg.sender, address(this), amount),
            "Token transfer failed"
        );

        // Update the stake data for the user
        stakes[msg.sender].amount += amount;
        stakes[msg.sender].timestamp = block.timestamp;

        emit Staked(msg.sender, amount);
    }

    /// @notice Unstake all want tokens that the user has staked
    function withdraw() external returns(uint){
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No tokens to unstake");

        uint256 amountToUnstake = userStake.amount;

        // Reset the user's stake data
        userStake.amount = 0;
        userStake.timestamp = 0;

        // Transfer want tokens back to the user
        require(
            want.transfer(msg.sender, amountToUnstake),
            "Token transfer failed"
        );

        emit Unstaked(msg.sender, amountToUnstake);

        return(amountToUnstake);
    }

    /// @notice Get the stake details for a user
    /// @param user The address of the user
    /// @return amount The amount of tokens staked
    /// @return timestamp The timestamp when the stake started
    function balanceOf(address user)
        external
        view
        returns (uint256 amount, uint256 timestamp)
    {
        Stake memory userStake = stakes[user];
        return (userStake.amount, userStake.timestamp);
    }
}