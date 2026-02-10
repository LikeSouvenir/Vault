# CompoundUsdcStrategy
[Git Source](https://github.com/LikeSouvenir/Vault/blob/36fdd71da90fb692ff334a0a992d2c455d783bcd/src/StrategyExamples/CompoundUsdcStrategy.sol)

**Inherits:**
[BaseStrategy](/src/BaseStrategy.sol/abstract.BaseStrategy.md)

**Title:**
Compound USDC Strategy

Strategy for providing USDC liquidity to Compound V3 protocol

Earns interest on USDC deposits and collects COMP rewards, swapping them to USDC


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


### COMET
Compound V3 Comet lending protocol contract


```solidity
IComet private immutable COMET
```


### COMET_REWARD
Compound V3 Rewards contract for COMP distribution


```solidity
ICometRewards public immutable COMET_REWARD
```


### UNISWAP_ROUTER
Uniswap V2 Router for swapping COMP to USDC


```solidity
address public immutable UNISWAP_ROUTER
```


### COMP
Address of the COMP reward token


```solidity
address public immutable COMP
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
    address uniswapRouter_,
    address addressAggregatorV3_
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
|`addressAggregatorV3_`|`address`|Address of Chainlink AddressAggregatorV3|


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

