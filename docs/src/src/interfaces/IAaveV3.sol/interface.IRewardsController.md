# IRewardsController
[Git Source](https://github.com/LikeSouvenir/Vault/blob/8ed516f562cdb60c3e34b4e86693fe2158400602/src/interfaces/IAaveV3.sol)

**Title:**
Rewards Controller Interface

Interface for managing reward distribution in lending protocols

Handles claiming and querying of incentive rewards (e.g., Aave's liquidity mining rewards)


## Functions
### claimRewards

Claims accumulated rewards for specified assets

Transfers earned rewards to the beneficiary address


```solidity
function claimRewards(address[] calldata assets, uint256 amount, address to, address reward)
    external
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`address[]`|Array of asset addresses for which to claim rewards|
|`amount`|`uint256`|The amount of rewards to claim (max uint256 for all available)|
|`to`|`address`|The address that will receive the claimed rewards|
|`reward`|`address`|The address of the reward token to claim|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of rewards actually claimed|


### getUserRewards

Queries unclaimed rewards for a user

Returns the accumulated but unclaimed reward amount for specific assets


```solidity
function getUserRewards(address[] calldata assets, address user, address reward) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`address[]`|Array of asset addresses to check for rewards|
|`user`|`address`|The address of the user to query|
|`reward`|`address`|The address of the reward token to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of unclaimed rewards available|


