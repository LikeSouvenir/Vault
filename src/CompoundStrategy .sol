// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {BaseStrategy} from "./BaseStrategy.sol";

contract CompoundStrategy  is BaseStrategy{
    address _investTo;

    constructor(string memory name_, address vault_ ) BaseStrategy(0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238, name_, vault_) {
        // _investTo = StackingMock(investTo_);
        // assetToken = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    }

    function _pull(uint256 _amount ) internal virtual override returns (uint256) {
        // return _investTo.withdraw(_amount);
    }

    function _push(uint256 _amount) internal virtual override {
        // _asset.approve(address(_investTo), _amount);
        // _investTo.deposite(address(this), _amount);
    }

    function _harvestAndReport() internal virtual override returns (uint256 _totalAssets) {
        // return _investTo.balanceAndResult(address(this));
    }
}