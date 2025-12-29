// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {BaseStrategy} from "./BaseStrategy.sol";

contract AaveStrategy is BaseStrategy{
    address _investTo;

    constructor(IERC20 assetToken_, string memory name_, address vault_ ) BaseStrategy(address(assetToken_), name_, vault_) {
        // _investTo = StackingMock(investTo_);
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