// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {BaseStrategy} from "../../contracts/BaseStrategy.sol";

import {StackingMock} from "./StackingMock.sol";
import {Erc20Mock} from "./Erc20Mock.sol";

import {Test} from "forge-std/Test.sol"; 
import {stdStorage, StdStorage} from "forge-std/Test.sol"; 
import {stdError} from "forge-std/Test.sol";
import {console} from "forge-std/Test.sol";

contract StackingStrategyMock is BaseStrategy {
    StackingMock stackingMock;

    constructor( Erc20Mock assetToken_, address vault_ ) BaseStrategy(address(assetToken_), "StackingStrategyMock", vault_) {
        stackingMock = new StackingMock(assetToken_);
    }

    function _pull(uint256 _amount ) internal virtual override returns (uint256) {
        return stackingMock.withdraw(_amount);
    }

    function _push(uint256 _amount) internal virtual override {
        stackingMock.deposite(msg.sender, _amount);
    }

    function _harvestAndReport() internal virtual override returns (uint256 _totalAssets) {
        return stackingMock.getBalance(msg.sender);
    }
}