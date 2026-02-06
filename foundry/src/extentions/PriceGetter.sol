// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "@foundry-chainlink-toolkit/src/interfaces/feeds/AggregatorV3Interface.sol";

library PriceGetter {
    error OldParamUpdatedAt(uint256 updateAt);

    function getPrice(address addressAggregatorV3, uint256 updateMaxTime) internal view returns (uint256 price) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(addressAggregatorV3);

        (, int256 answer,, uint256 updatedAt,) = priceFeed.latestRoundData();

        require(updatedAt > block.timestamp - updateMaxTime, OldParamUpdatedAt(updatedAt));

        price = uint256(answer) * 1e10;
    }

    function getConversionPrice(address addressAggregatorV3, uint256 updateMaxTime, uint256 amount)
        internal
        view
        returns (uint256)
    {
        return (getPrice(addressAggregatorV3, updateMaxTime) * amount) / 1e18;
    }
}
