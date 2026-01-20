# CompoundUsdcStrategy
[Git Source](https://github.com/LikeSouvenir/Vault/blob/8ed516f562cdb60c3e34b4e86693fe2158400602/src/StrategyExamples/CompoundUsdcStrategy.sol)

**Inherits:**
[BaseStrategy](/src/BaseStrategy.sol/abstract.BaseStrategy.md)

**Title:**
Compound USDC Strategy

Strategy for providing USDC liquidity to Compound V3 protocol

Earns interest on USDC deposits and collects COMP rewards, swapping them to USDC


## State Variables
### comet
Compound V3 Comet lending protocol contract


```solidity
IComet private immutable comet
```


### cometReward
Compound V3 Rewards contract for COMP distribution


```solidity
ICometRewards public immutable cometReward
```


### comp
Address of the COMP reward token


```solidity
address public immutable comp
```


### uniswapRouter
Uniswap V2 Router for swapping COMP to USDC


```solidity
address public immutable uniswapRouter
```


### swapDeadline
Deadline duration for Uniswap swaps (default: 1 hour)


```solidity
uint256 public swapDeadline = 1 hours
```


## Functions
### constructor

Initializes the Compound USDC strategy

Sets up Compound V3 integration and approves tokens for protocol interactions


```solidity
constructor(
    address comet_,
    address token_,
    string memory name_,
    address vault_,
    address cometRewards_,
    address rewardToken_,
    address uniswapRouter_
) BaseStrategy(token_, name_, vault_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`comet_`|`address`|Address of the Compound V3 Comet contract|
|`token_`|`address`|Address of the base asset (USDC)|
|`name_`|`string`|Strategy name for identification|
|`vault_`|`address`|Address of the vault this strategy serves|
|`cometRewards_`|`address`|Address of Compound V3 Rewards contract|
|`rewardToken_`|`address`|Address of the COMP reward token|
|`uniswapRouter_`|`address`|Address of Uniswap V2 Router|


### _pull

Withdraws assets from Compound when needed

Claims rewards, swaps to USDC, then withdraws from Compound if needed


```solidity
function _pull(uint256 _amount) internal virtual override returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|Amount of assets requested for withdrawal|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The actual amount withdrawn|


### _push

Deposits assets into Compound V3


```solidity
function _push(uint256 _amount) internal virtual override;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|Amount of assets to deposit|


### _harvestAndReport

Calculates total assets managed by the strategy

Returns the balance of supplied assets in Compound (in USDC terms)


```solidity
function _harvestAndReport() internal virtual override returns (uint256 _totalAssets);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_totalAssets`|`uint256`|Total value of assets in USDC terms|


### _claimRewards

Claims COMP rewards from Compound V3

`shouldAccrue` parameter is set to true to update interest before claiming

Uses try-catch to handle cases where claim might fail


```solidity
function _claimRewards() internal;
```

### _swapRewardsToAsset

Swaps COMP rewards to the base asset (USDC)

Uses 0 minimum output - accepting any exchange rate

Uses Uniswap V2 with a fixed path: COMP → USDC


```solidity
function _swapRewardsToAsset() internal;
```

### harvest

Manually trigger reward harvesting and swapping

Claims COMP rewards and swaps them to USDC immediately

**Note:**
role: KEEPER_ROLE Only callable by keepers


```solidity
function harvest() external onlyRole(KEEPER_ROLE);
```

### setSwapDeadline

Update swap deadline duration

**Note:**
role: DEFAULT_ADMIN_ROLE Only callable by admin


```solidity
function setSwapDeadline(uint256 delay) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`delay`|`uint256`|New deadline duration in seconds|


