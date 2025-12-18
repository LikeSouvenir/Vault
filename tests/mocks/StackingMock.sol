// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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

    function withdraw(uint amount) external returns(uint returnAmount){
        uint dep = _deposits[msg.sender];
        require(amount <= dep, "more that balance");

        _deposits[msg.sender] -= amount;

        returnAmount = amount * 110 / 100; // + 10%

        _mockToken.mint(msg.sender, returnAmount);
    }

    function setIsReturnedProfit(bool isProfit) external {
        isReturnedProfit = isProfit;
    }

    function balanceAndResult(address user) public view returns(uint balance) {
            balance = _deposits[user];
        if (isReturnedProfit) {
            balance += balance * 10 / 100; // + 10%
        } else {
            balance -= balance * 10 / 100; // + 10%
        }
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