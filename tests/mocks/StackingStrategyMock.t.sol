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

    constructor( StackingMock stackingMock_, Erc20Mock assetToken_, address vault_ ) BaseStrategy(address(assetToken_), "StackingStrategyMock", vault_) {
        stackingMock = stackingMock_;
    }

    function _pull(uint256 _amount ) internal override returns (uint256) {
        return stackingMock.withdraw(_amount);
    }

    function _push(uint256 _amount) internal override {
        _asset.approve(address(stackingMock), _amount);
        stackingMock.deposite(address(this), _amount);
    }

    function _harvestAndReport() internal view override returns (uint256 _totalAssets) {
        return stackingMock.balanceAndResult(address(this));
    }
}