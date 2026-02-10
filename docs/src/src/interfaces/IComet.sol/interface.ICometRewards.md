# ICometRewards
[Git Source](https://github.com/LikeSouvenir/Vault/blob/36fdd71da90fb692ff334a0a992d2c455d783bcd/src/interfaces/IComet.sol)

**Title:**
Compound V3 Rewards Interface

Interface for claiming rewards in Compound V3 protocol

Handles COMP token rewards distribution for suppliers and borrowers


## Functions
### claim

Claims accrued rewards for an account

Transfers COMP rewards to the account based on their activity


```solidity
function claim(address comet, address account, bool shouldAccrue) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`comet`|`address`|The address of the Comet market|
|`account`|`address`|The address of the account to claim rewards for|
|`shouldAccrue`|`bool`|Whether to accrue interest before claiming|


### getRewardOwed

Gets the amount of rewards owed to an account

Calculates unclaimed COMP rewards for a specific account


```solidity
function getRewardOwed(address comet, address account) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`comet`|`address`|The address of the Comet market|
|`account`|`address`|The address of the account to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of COMP rewards owed to the account|


