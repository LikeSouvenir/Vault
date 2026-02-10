# AaveUsdcStrategy
[Git Source](https://github.com/LikeSouvenir/Vault/blob/36fdd71da90fb692ff334a0a992d2c455d783bcd/src/StrategyExamples/AaveUsdcStrategy.sol)

**Inherits:**
[BaseStrategy](/src/BaseStrategy.sol/abstract.BaseStrategy.md)

**Title:**
Aave USDC Strategy

Strategy for providing USDC liquidity to Aave V3 protocol

Earns interest on USDC deposits and collects AAVE rewards, swapping them to USDC


## State Variables
### MAX_BPS

```solidity
uint16 private constant MAX_BPS = 10_000
```


### MIN_BPS

```solidity
uint16 private constant MIN_BPS = 1
```


### ADDRESS_AGGREGATOR_V3
ADDRESS_AGGREGATOR_V3 chainlink


```solidity
address public immutable ADDRESS_AGGREGATOR_V3
```


### AAVE_POOL
Aave V3 Pool contract for lending operations


```solidity
IPool public immutable AAVE_POOL
```


### A_TOKEN
aUSDC token representing USDC deposits in Aave


```solidity
IAToken public immutable A_TOKEN
```


### REWARDS_CONTROLLER
Aave Rewards Controller for claiming incentive rewards


```solidity
IRewardsController public immutable REWARDS_CONTROLLER
```


### REWARD_TOKEN
Address of the reward token (AAVE)


```solidity
address public immutable REWARD_TOKEN
```


### UNISWAP_V2_ROUTER
Uniswap V2 Router for swapping rewards to USDC


```solidity
address public immutable UNISWAP_V2_ROUTER
```


### updateMaxTime
Max difference between AddressAggregatorV3.latestRoundData.updatedAt and now


```solidity
uint96 public updateMaxTime = 1 hours
```


### swapDeadline
Deadline duration for Uniswap swaps, by default is 1 hour


```solidity
uint96 public swapDeadline = 1 hours
```


### slippageBps
Slippage tolerance in basis points, by default is 0,5%


```solidity
uint16 public slippageBps = 50
```


### minSwapAmount
Minimum swap amount in USDC to trigger swap, by default is 2000e18


```solidity
uint256 public minSwapAmount = 2000e18
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
    address uniswapRouter_,
    address addressAggregatorV3_
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
|`addressAggregatorV3_`|`address`|Address of Chainlink AddressAggregatorV3|


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
function setSwapDeadline(uint96 newSwapDeadline) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newSwapDeadline`|`uint96`|New deadline duration in seconds|


### setUpdateMaxTime

Updates the maximum time for price updates from aggregator

Prevents using stale prices by ensuring updates occur within reasonable timeframes

**Note:**
role: DEFAULT_ADMIN_ROLE Only callable by admin


```solidity
function setUpdateMaxTime(uint96 newMaxTime) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newMaxTime`|`uint96`|New maximum update time in seconds|


### setSlippageBps

Updates the slippage tolerance for swaps, by default = 2000e18

Prevents front-running and excessive price impact during COMP→USDC swaps

**Note:**
role: DEFAULT_ADMIN_ROLE Only callable by admin


```solidity
function setSlippageBps(uint16 newSlippageBps) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newSlippageBps`|`uint16`|New slippage tolerance in basis points (1-10000)|


### setMinSwapAmount

Updates the minimum COMP amount to trigger a swap

Prevents wasteful gas spending on small reward swaps

**Note:**
role: DEFAULT_ADMIN_ROLE Only callable by admin


```solidity
function setMinSwapAmount(uint256 newMinAmount) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newMinAmount`|`uint256`|New minimum amount in USDC terms (18 decimals)|


## Events
### SlippageUpdated

```solidity
event SlippageUpdated(uint256 newSlippageBps);
```

### MinSwapAmountUpdated

```solidity
event MinSwapAmountUpdated(uint256 newMinAmount);
```

### SwapExecuted

```solidity
event SwapExecuted(uint256 amountIn, uint256 amountOut, uint256 minAmountOut);
```

## Errors
### IncorrectMin

```solidity
error IncorrectMin();
```

### IncorrectMax

```solidity
error IncorrectMax();
```

### LessThanMinimumSwapAmount

```solidity
error LessThanMinimumSwapAmount(uint256 currentAmount);
```

### IncorrectMinTime

```solidity
error IncorrectMinTime();
```

