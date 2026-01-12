// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Erc20Mock} from "./Erc20Mock.sol";

contract StackingMock {
    struct UserInfo {
        uint256 balance;
        uint256 profit;
        uint256 loss;
    }
    mapping(address => UserInfo) _deposits;
    Erc20Mock _mockToken;
    bool isReturnedProfit;

    constructor(Erc20Mock mockToken) {
        _mockToken = mockToken;
        isReturnedProfit = true;
    }

    function deposit(address to, uint256 amount) external {
        bool check = _mockToken.transferFrom(msg.sender, address(this), amount);
        require(check, "bad transfer");
        _deposits[to].balance += amount;
    }

    function updateInvest(address to) external {
        uint256 balance = _deposits[to].balance;
        if (isReturnedProfit) {
            _deposits[to].profit += calculateTenPercent(balance);
        } else {
            _deposits[to].loss += calculateTenPercent(balance);
        }
    }

    function withdraw(uint256 value) external returns (uint256 amount) {
        UserInfo storage info = _deposits[msg.sender];
        uint256 balance = info.balance + info.profit - info.loss;
        require(balance >= value, "more that can");

        info.balance = balance - value;
        info.profit = 0;
        info.loss = 0;

        _mockToken.mint(msg.sender, value);

        return value;
    }

    function balanceAndResult(address user) public view returns (uint256 balance) {
        UserInfo storage info = _deposits[user];
        balance = info.balance + info.profit - info.loss;
    }

    function setIsReturnedProfit(bool isProfit) external {
        isReturnedProfit = isProfit;
    }

    function calculateTenPercent(uint256 value) internal pure returns (uint256) {
        return value * 10 / 100; // 10%
    }

    function getBalance(address user) external view returns (uint256) {
        return _deposits[user].balance;
    }

    function calculateProfit(uint256 profit) public pure returns (uint256) {
        return profit * 10 / 100;
    }

    function calculateLoss(uint256 loss) public pure returns (uint256) {
        return loss * 10 / 100;
    }
}
