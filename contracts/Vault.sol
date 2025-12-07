// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AssetERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Vault is ERC4626{
    uint _maxStrategyCount;
    uint _mxanagmentFee;
    address _feeRecipient;
    IStrategy[] strategies;
    mapping (address => StrategyParams) strategiesMap;

    struct StrategyParams {
        uint256 performanceFee;  // Strategist's fee (basis points)
        uint256 activation;  // Activation block.timestamp
        uint256 debtRatio;  // Maximum borrow amount (in BPS of total assets)
        uint256 minDebtPerHarvest;  // Lower limit on the increase of debt since last harvest
        uint256 maxDebtPerHarvest;  // Upper limit on the increase of debt since last harvest
        uint256 lastReport;  // block.timestamp of the last time a report occured
        uint256 totalDebt;  // Total outstanding debt that Strategy has
        uint256 totalGain;  // Total returns that Strategy has realized for Vault
        uint256 totalLoss;  // Total losses that Strategy has realized for Vault
    }

    constructor() ERC4626(new AssetERC20("Asset Token", "ASSET")) ERC20("Share Token", "SHARE") { // string memory name_, string memory symbol_  

    }

    function totalAssets() public view override returns (uint256) {
        // strategies перебираем их балансы
        return IERC20(asset()).balanceOf(address(this)) + strategieBalance();
    }

    function _withdraw( address caller, address receiver, address owner, uint256 assets, uint256 shares ) internal override {
        uint currentBalance = IERC20(asset()).balanceOf(address(this));
        if (currentBalance < assets){
            // если не хватит на этой стратегии?
            transferFrom(address(getStrategyMinProfit()), address(this), assets - currentBalance);
        }
        
        super._withdraw(caller, receiver, owner, assets, shares);
    }

    function strategieBalance() public view returns(uint) {
        // return strategie.estimatedTotalAssets();
    }

    function remove(IStrategy newStrategy) external {
        // strategie.migrate(address(newStrategy)); // перевод с остновкойсо старой стратегии на другую
        // strategie = newStrategy;
    }
    function add(IStrategy newStrategy) external {
        // 1193 https://github.com/yearn/yearn-vaults/blob/develop/contracts/Vault.vy
        // require(newStrategy != address(0));

        // approve(address(newStrategy), balanceOf(address(this)));
    }
    function update(IStrategy newStrategy) external {}
    function run(IStrategy newStrategy) external {}
    function pause(IStrategy newStrategy) external {}
    function unpause(IStrategy newStrategy) external {}

    function getStrategyMinProfit() internal view returns(IStrategy addressWithMinProfit) {
        uint minProfit;
        for (uint i = 0; i < strategies.length; ++i) {
            StrategyParams memory currentStrategy = strategiesMap[address(strategies[i])];
            uint currecntAmount = currentStrategy.totalGain - currentStrategy.totalLoss;

            if (minProfit < currecntAmount) {
                minProfit = currecntAmount;
                addressWithMinProfit = strategies[i];
            }
        }
    }
    function setWithdrawalQueue(address[] queue) external {
        
    }
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