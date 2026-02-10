# IAToken
[Git Source](https://github.com/LikeSouvenir/Vault/blob/36fdd71da90fb692ff334a0a992d2c455d783bcd/src/interfaces/IAaveV3.sol)

**Inherits:**
IERC20

**Title:**
aToken Interface

Interface for Aave's interest-bearing tokens

ERC20 tokens that represent a deposit in the lending pool and accrue interest over time


## Functions
### UNDERLYING_ASSET_ADDRESS

Returns the address of the underlying asset

This token represents a wrapped version of the underlying asset


```solidity
function UNDERLYING_ASSET_ADDRESS() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The address of the underlying ERC20 token|


