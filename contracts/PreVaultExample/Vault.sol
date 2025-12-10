// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Vault/AssetERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import {Slots} from "../Vault/utils/elements.sol";
import {IFeeConfig} from "./interfaces/IFeeConfig.sol";

contract Vault is ERC4626, IFeeConfig{
    uint16 _managementFee; // The percent in basis points of profit that is charged as a fee.
    address feeRecipient; // The address to pay the `performanceFee` to.

    string __name = "Asset Token";
    string __symbol = "ASSET";
    constructor() ERC4626(IERC20(new AssetERC20(__name, __symbol))) ERC20("Share Token", "SHARE") { // string memory name_, string memory symbol_  

    }
    function feeConfig() external view returns (uint16, address) {
        return (_managementFee, feeRecipient);
    }
// Поддержка нескольких стратегий одним волтом.

    
    // function totalAssets() public view override returns (uint256) {
        // strategies перебираем их балансы
        // return IERC20(asset()).balanceOf(address(this)) + strategieBalance();
    // }

    function _withdraw( address caller, address receiver, address owner, uint256 assets, uint256 shares ) internal override {
        // uint currentBalance = IERC20(asset()).balanceOf(address(this));
        // if (currentBalance < assets){
        //     // если не хватит на этой стратегии?
        //     transferFrom(address(getStrategyMinProfit()), address(this), assets - currentBalance);
        // }
        
        // super._withdraw(caller, receiver, owner, assets, shares);
    }

    function strategieBalance() public view returns(uint) {
        // return strategie.estimatedTotalAssets();
    }

    function remove(IStrategy strategy) external {
        // strategie.migrate(address(strategy)); // перевод с остновкойсо старой стратегии на другую
        // strategie = newStrategy;
    }
    function add(IStrategy strategy) external {
        // 1193 https://github.com/yearn/yearn-vaults/blob/develop/contracts/Vault.vy
        // require(newStrategy != address(0));

        // approve(address(newStrategy), balanceOf(address(this)));
    }
    function run(IStrategy strategy) external {}
    function pause(IStrategy strategy) external {}
    function unpause(IStrategy strategy) external {}

    // function setWithdrawalQueue(address[] queue) external {
        
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