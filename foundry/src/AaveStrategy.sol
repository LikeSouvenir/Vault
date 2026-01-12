// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {BaseStrategy} from "./BaseStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AaveStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    address _investTo;

    constructor(
        address assetToken_,
        string memory name_,
        address vault_
    ) BaseStrategy(assetToken_, name_, vault_) {
        // _investTo = StackingMock(investTo_);
    }

    function _pull(uint256 _amount) internal virtual override returns (uint256) {
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
