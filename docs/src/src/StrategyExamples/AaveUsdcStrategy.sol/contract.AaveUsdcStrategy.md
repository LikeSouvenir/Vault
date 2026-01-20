# AaveUsdcStrategy
[Git Source](https://github.com/LikeSouvenir/Vault/blob/8ed516f562cdb60c3e34b4e86693fe2158400602/src/StrategyExamples/AaveUsdcStrategy.sol)

**Inherits:**
[BaseStrategy](/src/BaseStrategy.sol/abstract.BaseStrategy.md)

**Title:**
Aave USDC Strategy

Strategy for providing USDC liquidity to Aave V3 protocol

Earns interest on USDC deposits and collects AAVE rewards, swapping them to USDC


## State Variables
### aavePool
Aave V3 Pool contract for lending operations


```solidity
IPool public immutable aavePool
```


### aToken
aUSDC token representing USDC deposits in Aave


```solidity
IAToken public immutable aToken
```


### rewardsController
Aave Rewards Controller for claiming incentive rewards


```solidity
IRewardsController public immutable rewardsController
```


### rewardToken
Address of the reward token (AAVE)


```solidity
address public immutable rewardToken
```


### uniswapV2Router
Uniswap V2 Router for swapping rewards to USDC


```solidity
address public immutable uniswapV2Router
```


### swapDeadline
Deadline duration for Uniswap swaps (default: 1 hour)


```solidity
uint256 public swapDeadline = 1 hours
```


## Functions
### constructor

Initializes the Aave USDC strategy

Sets up Aave V3 integration and approves tokens for protocol interactions


```solidity
constructor(
    address pool_,
    address token_,
    string memory name_,
    address vault_,
    address aToken_,
    address rewardsController_,
    address rewardToken_,
    address uniswapRouter_
) BaseStrategy(token_, name_, vault_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pool_`|`address`|Address of the Aave V3 Pool contract|
|`token_`|`address`|Address of the base asset (USDC)|
|`name_`|`string`|Strategy name for identification|
|`vault_`|`address`|Address of the vault this strategy serves|
|`aToken_`|`address`|Address of the aUSDC token|
|`rewardsController_`|`address`|Address of Aave Rewards Controller|
|`rewardToken_`|`address`|Address of the reward token (AAVE)|
|`uniswapRouter_`|`address`|Address of Uniswap V2 Router|


### _pull

Withdraws assets from Aave when needed

If insufficient balance, claims rewards, swaps them, and withdraws from Aave


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

Deposits assets into Aave V3


```solidity
function _push(uint256 _amount) internal virtual override;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|Amount of assets to deposit|


### _harvestAndReport

Calculates total assets managed by the strategy

Includes both USDC balance and aUSDC balance (converted to USDC)


```solidity
function _harvestAndReport() internal virtual override returns (uint256 _totalAssets);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_totalAssets`|`uint256`|Total value of assets in USDC terms|


### _claimAndSwapRewards

Claims AAVE rewards and swaps them to USDC

Internal function called during withdrawals and reporting


```solidity
function _claimAndSwapRewards() internal;
```

### _swapRewardsToAsset

Swaps reward tokens to the base asset (USDC)

Uses Uniswap V2 with a fixed path: AAVE to USDC


```solidity
function _swapRewardsToAsset() internal;
```

### harvest

Manually trigger reward harvesting

Can be called by keeper to optimize gas costs

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


