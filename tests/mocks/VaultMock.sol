// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {BaseStrategy} from "../../contracts/BaseStrategy.sol";

import {Erc20Mock} from "./Erc20Mock.sol";
import {StackingMock} from "./StackingMock.sol";

interface IVault {
    function report(BaseStrategy strategy) external;
    function rebalance(BaseStrategy strategy) external returns(uint amount);
}

contract VaultMock is IVault {
    Erc20Mock assetToken;
    uint256 profit; 
    uint256 loss;
    uint strategyTotalAsset;

    constructor(Erc20Mock _assetToken) {
        assetToken = _assetToken;
    }

    function report(BaseStrategy strategy) external {
        strategyTotalAsset = strategy.lastTotalAssets();
        (profit, loss) = strategy.report();
        
        if (profit > 0) {
            strategyTotalAsset += profit;
            assetToken.mint(address(strategy), profit);

        } else if (strategyTotalAsset > loss) {
            strategyTotalAsset -= loss;
            assetToken.burn(address(strategy), loss);

        } else revert("spend all");
    }

    function rebalance(BaseStrategy strategy) external returns(uint amount) {
        if (profit > 0) {
            assetToken.mint(address(strategy), profit);
        } else {
            assetToken.burn(address(strategy), profit);
        }

        return strategyTotalAsset;
    }
}