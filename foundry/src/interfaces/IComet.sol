// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IComet {
    function balanceOf(address account) external view returns (uint256);
    function supply(address asset, uint256 amount) external;
    function withdraw(address asset, uint256 amount) external;
    function baseToken() external view returns (address);
    function getSupplyRate(uint256 utilization) external view returns (uint64);
    function getBorrowRate(uint256 utilization) external view returns (uint64);
    function totalSupply() external view returns (uint256);
    function totalBorrow() external view returns (uint256);
    function hasPermission(address owner, address manager) external view returns (bool);
}

interface ICometRewards {
    function claim(address comet, address account, bool shouldAccrue) external;
    function getRewardOwed(address comet, address account) external returns (uint256);
}
