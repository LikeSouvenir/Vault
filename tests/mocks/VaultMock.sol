// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {BaseStrategy} from "../../contracts/BaseStrategy.sol";

import {Erc20Mock} from "./Erc20Mock.sol";

interface IVault {
    function report(BaseStrategy strategy) external;
    function rebalance(BaseStrategy strategy) external;
    function strategyBalance(BaseStrategy strategy) external view returns(uint);
}

contract VaultMock is IVault {
    Erc20Mock assetToken;
    uint256 profit; 
    uint256 loss;
    uint strategyTotalAsset;
    bool isRebalanceWork;


    struct StrategyInfo {
        uint balance;
        uint96 lastTakeTime;
        uint16 sharePercent;
        uint16 performanceFee;// The percent in basis points of profit that is charged as a fee.
    }
    mapping (BaseStrategy => uint) balances;

    constructor(Erc20Mock _assetToken) {
        assetToken = _assetToken;
        isRebalanceWork = false;
    }

    function setStrategyBalance(BaseStrategy strategy, uint balance) external  {
        balances[strategy] = balance;
    }


    function strategyBalance(BaseStrategy strategy) external view returns(uint) {
        return balances[strategy];
    }

    function report(BaseStrategy strategy) external {
        strategyTotalAsset = strategy.lastTotalAssets();

        uint balance = assetToken.balanceOf(address(strategy));
        if (strategyTotalAsset > balance) {
            assetToken.mint(address(strategy), strategyTotalAsset - balance);
        } else {
            assetToken.burn(address(strategy), balance - strategyTotalAsset);
        }
        (profit, loss) = strategy.report();
        
    }

    function rebalance(BaseStrategy strategy) external {
        if (!isRebalanceWork) {
            return;
        }
        if (profit > 0) {
            strategyTotalAsset += profit;

            assetToken.mint(address(this), profit);
            
            assetToken.approve(address(strategy), profit);
            strategy.push(profit);

        } else if (strategyTotalAsset > loss) {
            strategyTotalAsset -= loss;
            
            strategy.pull(loss);
        }
    }
}