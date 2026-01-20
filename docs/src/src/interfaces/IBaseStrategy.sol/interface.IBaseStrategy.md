# IBaseStrategy
[Git Source](https://github.com/LikeSouvenir/Vault/blob/8ed516f562cdb60c3e34b4e86693fe2158400602/src/interfaces/IBaseStrategy.sol)

**Inherits:**
IAccessControl, IERC165

**Title:**
IBaseStrategy - Interface for Base Strategy Contract

Defines the interface for asset management strategies


## Functions
### rebalanceAndReport

Call rebalance and report from vault


```solidity
function rebalanceAndReport() external returns (uint256 profit, uint256 loss, uint256 balance);
```

### push

Deposit assets into strategy


```solidity
function push(uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|Amount of assets to deposit|


### pull

Withdraw assets from strategy


```solidity
function pull(uint256 amount) external returns (uint256 value);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|Amount of assets to withdraw|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`value`|`uint256`|Actual amount withdrawn|


### report

Report on strategy performance


```solidity
function report() external returns (uint256 profit, uint256 loss);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`profit`|`uint256`|Profit since last report|
|`loss`|`uint256`|Loss since last report|


### takeAndClose

Withdraw all assets and close strategy


```solidity
function takeAndClose() external returns (uint256 amount);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|Amount of assets withdrawn|


### emergencyWithdraw

Emergency withdraw all assets


```solidity
function emergencyWithdraw() external returns (uint256 amount);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|Amount of assets withdrawn|


### pause

Pause strategy operation


```solidity
function pause() external;
```

### unpause

Resume strategy operation


```solidity
function unpause() external;
```

### isPaused

Check if strategy is paused


```solidity
function isPaused() external view returns (bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true if strategy is paused|


### asset

Get underlying asset address


```solidity
function asset() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|Asset address|


### vault

Get vault address


```solidity
function vault() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|Vault address|


### lastTotalAssets

Get last recorded balance


```solidity
function lastTotalAssets() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Asset balance|


### name

Get strategy name


```solidity
function name() external view returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|Strategy name|


## Events
### StrategyPaused
Event emitted when strategy is paused


```solidity
event StrategyPaused(uint256 indexed timestamp);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`timestamp`|`uint256`|Block timestamp|

### StrategyUnpaused
Event emitted when strategy is unpaused


```solidity
event StrategyUnpaused(uint256 indexed timestamp);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`timestamp`|`uint256`|Block timestamp|

### Pull
Event emitted when assets are pulled from strategy


```solidity
event Pull(uint256 assetPull);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assetPull`|`uint256`|Amount of assets pulled|

### Push
Event emitted when assets are pushed to strategy


```solidity
event Push(uint256 assetPush);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assetPush`|`uint256`|Amount of assets pushed|

### Report
Event emitted when strategy report is generated


```solidity
event Report(uint256 indexed time, uint256 indexed profit, uint256 indexed loss);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`time`|`uint256`|Block timestamp|
|`profit`|`uint256`|Profit amount|
|`loss`|`uint256`|Loss amount|

### EmergencyWithdraw
Event emitted on emergency withdrawal


```solidity
event EmergencyWithdraw(uint256 timestamp, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`timestamp`|`uint256`|Block timestamp|
|`amount`|`uint256`|Amount withdrawn|

