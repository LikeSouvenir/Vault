// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import "./BaseStrategy.sol";
import "./Staking.sol";
 
 contract Strategy is BaseStrategy {
    using SafeERC20 for ERC20;
    Staking staking_;

    constructor( address _asset, string memory _name, Staking _staking ) BaseStrategy(_asset, _name, msg.sender, address(0), address(this)) {
        staking_ = _staking;
    }

    function _deposit(uint256 _amountWant) internal override { /*must permissin grand*/
        // SafeERC20.safeTransferFrom(_want, address(this), КУДА, _amountWant);

        staking_.deposite(_amountWant);
    }

    function _withdraw(uint256 _amount) internal override returns(uint256) {/*must permissin grand*/
        // мб override изначальную функию, для передачи _amount

        return staking_.withdraw();
    }

    function _harvestAndReport() internal override returns(uint256 _totalAssets) { /*must permissin grand*/ 
        // урожай и отчет
        //      if(!TokenizedStrategy.isShutdown()) {
        //          _claimAndSellRewards();
        //      }
        //      _totalAssets = aToken.balanceOf(address(this)) + asset.balanceOf(address(this));
        staking_.deposite(100);

        (uint amount, ) = staking_.balanceOf(address(this));
        _totalAssets = _asset.balanceOf(address(this)) + amount;
    }

}