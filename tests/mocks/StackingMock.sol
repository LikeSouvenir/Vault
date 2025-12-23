// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Erc20Mock} from "./Erc20Mock.sol";

contract StackingMock {
    mapping(address => uint) _deposits;
    Erc20Mock _mockToken;
    bool isReturnedProfit;

    constructor(Erc20Mock mockToken) {
        _mockToken = mockToken;
        isReturnedProfit = true;
    }

    function deposite(address to, uint256 amount) external {
        _mockToken.transferFrom(msg.sender, address(this), amount);
        _deposits[to] += amount;
    }

    function withdraw(uint value) external returns(uint amount){
        uint balance = _deposits[msg.sender];
        require(balance >= value, "more that can");

        _deposits[msg.sender] -= value > balance ? balance : value;

        if (isReturnedProfit) {
            amount = value + calculateTenPercent(value);
        } else {
            amount = value - calculateTenPercent(value);
        }
        _mockToken.mint(msg.sender, amount);
    }

    function balanceAndResult(address user) public view returns(uint balance) {
        balance = _deposits[user];
        if (isReturnedProfit) {
            balance += calculateTenPercent(balance);
        } else {
            balance -= calculateTenPercent(balance);
        }
    }

    function setIsReturnedProfit(bool isProfit) external {
        isReturnedProfit = isProfit;
    }

    function calculateTenPercent(uint value) internal pure returns(uint) {
        return value * 10 / 100;// 10%
    }

    function getBalance(address user) external view returns(uint) {
        return _deposits[user];
    }

    function calculateProfit(uint profit) public pure returns(uint) {
        return profit * 10 / 100;
    }

    function calculateLoss(uint loss) public pure returns(uint) {
        return loss * 10 / 100;
    }
}