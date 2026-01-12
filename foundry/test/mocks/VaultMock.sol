// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {IBaseStrategy} from "../../src/interfaces/IBaseStrategy.sol";

import {Erc20Mock} from "./Erc20Mock.sol";

interface IVault {
    function report(IBaseStrategy strategy) external returns (uint256 profit, uint256 loss, uint256 balance);
    function rebalance(IBaseStrategy strategy) external;
    function strategyBalance(IBaseStrategy strategy) external view returns (uint256);
}

contract VaultMock is IVault {
    Erc20Mock internal assetToken;
    uint256 internal _profit;
    uint256 internal _loss;
    uint256 internal strategyTotalAsset;
    bool internal isRebalanceWork;

    struct StrategyInfo {
        uint256 balance;
        uint96 lastTakeTime;
        uint16 sharePercent;
        uint16 performanceFee; // The percent in basis points of profit that is charged as a fee.
    }
    mapping(IBaseStrategy => uint256) internal balances;

    constructor(Erc20Mock _assetToken) {
        assetToken = _assetToken;
        isRebalanceWork = false;
    }

    function setStrategyBalance(IBaseStrategy strategy, uint256 balance) external {
        balances[strategy] = balance;
    }

    function strategyBalance(IBaseStrategy strategy) external view returns (uint256) {
        return balances[strategy];
    }

    function report(IBaseStrategy strategy) external returns (uint256 profit, uint256 loss, uint256 balance) {
        strategyTotalAsset = strategy.lastTotalAssets();

        balance = assetToken.balanceOf(address(strategy));
        if (strategyTotalAsset > balance) {
            assetToken.mint(address(strategy), strategyTotalAsset - balance);
        } else {
            assetToken.burn(address(strategy), balance - strategyTotalAsset);
        }
        (profit, loss) = strategy.report();
        _profit = profit;
        _loss = loss;
    }

    function rebalance(IBaseStrategy strategy) external {
        if (!isRebalanceWork) {
            return;
        }
        if (_profit > 0) {
            strategyTotalAsset += _profit;

            assetToken.mint(address(this), _profit);

            assetToken.approve(address(strategy), _profit);
            strategy.push(_profit);
        } else if (strategyTotalAsset > _loss) {
            strategyTotalAsset -= _loss;

            strategy.pull(_loss);
        }
    }
}
