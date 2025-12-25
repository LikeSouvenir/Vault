// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Erc20Mock} from "./Erc20Mock.sol";

contract StackingMock {
    struct UserInfo {
        uint balance;
        uint profit;
        uint loss;
    }
    mapping(address => UserInfo) _deposits;
    Erc20Mock _mockToken;
    bool isReturnedProfit;

    constructor(Erc20Mock mockToken) {
        _mockToken = mockToken;
        isReturnedProfit = true;
    }

    function deposite(address to, uint256 amount) external {
        bool check = _mockToken.transferFrom(msg.sender, address(this), amount);
        require(check, "bad transfer");
        _deposits[to].balance += amount;
    }

    function updateInvest(address to) external {
        uint balance = _deposits[to].balance;
        if (isReturnedProfit) {
            _deposits[to].profit += calculateTenPercent(balance);
        } else {
            _deposits[to].loss += calculateTenPercent(balance);
        }
    }

    function withdraw(uint value) external returns(uint amount){
        UserInfo storage info = _deposits[msg.sender];
        uint balance = info.balance + info.profit - info.loss;
        require(balance >= value, "more that can");

        info.balance = balance - value;
        info.profit = 0;
        info.loss = 0;

        _mockToken.mint(msg.sender, value);

        return value;
    }

    function balanceAndResult(address user) public view returns(uint balance) {
        UserInfo storage info = _deposits[user];
        balance = info.balance + info.profit - info.loss;
    }

    function setIsReturnedProfit(bool isProfit) external {
        isReturnedProfit = isProfit;
    }

    function calculateTenPercent(uint value) internal pure returns(uint) {
        return value * 10 / 100;// 10%
    }

    function getBalance(address user) external view returns(uint) {
        return _deposits[user].balance;
    }

    function calculateProfit(uint profit) public pure returns(uint) {
        return profit * 10 / 100;
    }

    function calculateLoss(uint loss) public pure returns(uint) {
        return loss * 10 / 100;
    }
}