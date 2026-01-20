# IPool
[Git Source](https://github.com/LikeSouvenir/Vault/blob/8ed516f562cdb60c3e34b4e86693fe2158400602/src/interfaces/IAaveV3.sol)

**Title:**
Pool Interface

Interface for interacting with Aave lending pool or similar DeFi protocol

Provides core functions for supplying and withdrawing assets from liquidity pools


## Functions
### supply

Supplies assets to the pool on behalf of a user

Deposits tokens into the lending pool and mints aTokens in return


```solidity
function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the underlying asset to deposit|
|`amount`|`uint256`|The amount of tokens to supply|
|`onBehalfOf`|`address`|The address that will receive the aTokens|
|`referralCode`|`uint16`|Referral code used for tracking (0 for no referral)|


### withdraw

Withdraws assets from the pool

Burns aTokens and returns the underlying asset to the specified address


```solidity
function withdraw(address asset, uint256 amount, address to) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the underlying asset to withdraw|
|`amount`|`uint256`|The amount of tokens to withdraw (max uint256 for entire balance)|
|`to`|`address`|The address that will receive the withdrawn tokens|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The actual amount withdrawn|


