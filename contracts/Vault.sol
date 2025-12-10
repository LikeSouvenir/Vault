// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AssetERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import {Slots} from "./utils/elements.sol";

contract Vault is ERC4626{
    string __name = "Asset Token";
    string __symbol = "ASSET";
    constructor() ERC4626(IERC20(new AssetERC20(__name, __symbol))) ERC20("Share Token", "SHARE") { // string memory name_, string memory symbol_  

    }

    
    // function totalAssets() public view override returns (uint256) {
        // strategies перебираем их балансы
        // return IERC20(asset()).balanceOf(address(this)) + strategieBalance();
    // }

    // function _withdraw( address caller, address receiver, address owner, uint256 assets, uint256 shares ) internal override {
        // uint currentBalance = IERC20(asset()).balanceOf(address(this));
        // if (currentBalance < assets){
        //     transferFrom(address(getStrategyMinProfit()), address(this), assets - currentBalance);
        // }
        
        // super._withdraw(caller, receiver, owner, assets, shares);
    // }
}

interface IStrategy {
    function want() external view returns(address);
    function vault() external view returns(address);
    function isActive() external view returns(bool);
    function delegatedAssets() external view returns(uint256);
    function estimatedTotalAssets() external view returns(uint256);
    function withdraw(uint256 _amount ) external returns(uint256);
    function migrate(address _newStrategy) external returns(address);
}
// interface HealthCheck {
//     function check(address strategy, uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding, uint256 totalDebt) external view returns(bool);
//     function doHealthCheck(strategy: address) -> bool: view
//     function enableCheck(strategy: address): nonpayable
// }

interface BotManage {
}