// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPool {
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

interface IRewardsController {
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to,
        address reward
    ) external returns (uint256);

    function getUserRewards(
        address[] calldata assets,
        address user,
        address reward
    ) external view returns (uint256);
}

interface IAToken is IERC20 {
    // aToken interface
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}