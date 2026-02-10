# PriceGetter
[Git Source](https://github.com/LikeSouvenir/Vault/blob/36fdd71da90fb692ff334a0a992d2c455d783bcd/src/extentions/PriceGetter.sol)


## Functions
### getPrice


```solidity
function getPrice(address addressAggregatorV3, uint256 updateMaxTime) internal view returns (uint256 price);
```

### getConversionPrice


```solidity
function getConversionPrice(address addressAggregatorV3, uint256 updateMaxTime, uint256 amount)
    internal
    view
    returns (uint256);
```

## Errors
### OldParamUpdatedAt

```solidity
error OldParamUpdatedAt(uint256 updateAt);
```

