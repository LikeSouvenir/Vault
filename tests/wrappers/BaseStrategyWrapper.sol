// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {BaseStrategy} from "../../contracts/BaseStrategy.sol";

import {Erc20Mock} from "../mocks/Erc20Mock.sol";
import {StackingMock} from "../mocks/StackingMock.sol";

interface IVault {
    function report(BaseStrategy strategy) external;
    function rebalance(BaseStrategy strategy) external returns(uint amount);
}

contract BaseStrategyWrapper is BaseStrategy{
    StackingMock stackingMock;

    constructor(StackingMock stackingMock_, Erc20Mock assetToken_, string memory name_, address vault_ ) BaseStrategy(address(assetToken_), name_, vault_) {
        stackingMock = stackingMock_;
        _asset.approve(address(stackingMock), type(uint256).max);
    }

    function _pull(uint256 _amount ) internal virtual override returns (uint256) {
        return stackingMock.withdraw(_amount);
    }

    function _push(uint256 _amount) internal virtual override {
        stackingMock.deposite(address(this), _amount);
    }

    function _harvestAndReport() internal virtual override returns (uint256 _totalAssets) {
        return stackingMock.balanceAndResult(address(this));
    }
}
