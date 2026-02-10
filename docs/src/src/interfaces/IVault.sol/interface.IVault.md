# IVault
[Git Source](https://github.com/LikeSouvenir/Vault/blob/36fdd71da90fb692ff334a0a992d2c455d783bcd/src/interfaces/IVault.sol)

**Inherits:**
IERC4626, IERC165

**Title:**
IVault - Interface for Vault Contract

IERC-4626 compliant vault with strategy management capabilities


## Functions
### add

Adds a new strategy to the vault


```solidity
function add(IBaseStrategy newStrategy, uint16 sharePercent) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newStrategy`|`IBaseStrategy`|Address of the new strategy|
|`sharePercent`|`uint16`|Asset allocation percentage in basis points (0.01% = 1) for the strategy|


### migrate

Migrates assets from old strategy to new strategy


```solidity
function migrate(IBaseStrategy oldStrategy, IBaseStrategy newStrategy) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`oldStrategy`|`IBaseStrategy`|Old strategy to migrate from|
|`newStrategy`|`IBaseStrategy`|New strategy to migrate to|


### report

Reports on strategy performance (called by keeper)


```solidity
function report(IBaseStrategy strategy) external returns (uint256 profit, uint256 loss, uint256 balance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy to report on|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`profit`|`uint256`|Amount of strategy profit|
|`loss`|`uint256`|Amount of strategy loss|
|`balance`|`uint256`|current balance|


### rebalance

Rebalances a strategy (called by keeper)


```solidity
function rebalance(IBaseStrategy strategy) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy to rebalance|


### remove

Removes a strategy from the vault


```solidity
function remove(IBaseStrategy strategy) external returns (uint256 amountAssets);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy to remove|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amountAssets`|`uint256`|Amount of assets withdrawn|


### setWithdrawalQueue

Sets the withdrawal queue


```solidity
function setWithdrawalQueue(IBaseStrategy[MAXIMUM_STRATEGIES] memory queue) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`queue`|`IBaseStrategy[MAXIMUM_STRATEGIES]`|New strategy queue|


### setSharePercent

Sets allocation percentage for a strategy


```solidity
function setSharePercent(IBaseStrategy strategy, uint16 sharePercent) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy|
|`sharePercent`|`uint16`|New allocation percentage|


### setPerformanceFee

Sets performance fee for a strategy


```solidity
function setPerformanceFee(IBaseStrategy strategy, uint16 newFee) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy|
|`newFee`|`uint16`|New fee in basis points|


### setManagementFee

Sets management fee for the entire vault


```solidity
function setManagementFee(uint16 newFee) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newFee`|`uint16`|New fee in basis points|


### setFeeRecipient

Sets fee recipient address


```solidity
function setFeeRecipient(address recipient) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|New recipient address|


### setEmergencyBackupAddress

Sets emergency backup address


```solidity
function setEmergencyBackupAddress(address backupAddress) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`backupAddress`|`address`|New backup address|


### emergencyWithdraw

Emergency withdraw from strategy (admin only)


```solidity
function emergencyWithdraw(IBaseStrategy strategy) external returns (uint256 amount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy for emergency withdrawal|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|Amount of assets withdrawn|


### pause

Pauses a strategy


```solidity
function pause(IBaseStrategy strategy) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy to pause|


### unpause

Unpauses a strategy


```solidity
function unpause(IBaseStrategy strategy) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy to unpause|


### strategyGrantRole

GrantRole in a strategy


```solidity
function strategyGrantRole(IBaseStrategy strategy, bytes32 role, address account) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy  where granted role|
|`role`|`bytes32`|Role to be granted|
|`account`|`address`|Account granted role|


### strategyRevokeRole

GrantRole in a strategy


```solidity
function strategyRevokeRole(IBaseStrategy strategy, bytes32 role, address account) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy  where revoked role|
|`role`|`bytes32`|Role to be revoked|
|`account`|`address`|Account revoked role|


### withdrawalQueue

Gets withdrawal queue


```solidity
function withdrawalQueue() external view returns (IBaseStrategy[MAXIMUM_STRATEGIES] memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`IBaseStrategy[MAXIMUM_STRATEGIES]`|Queue of strategies for withdrawals|


### strategyPerformanceFee

Gets strategy performance fee


```solidity
function strategyPerformanceFee(IBaseStrategy strategy) external view returns (uint16);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint16`|Fee in basis points|


### managementFee

Gets vault management fee


```solidity
function managementFee() external view returns (uint16);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint16`|Fee in basis points|


### feeRecipient

Gets fee recipient address


```solidity
function feeRecipient() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|Recipient address|


### emergencyBackupAddress

Gets emergency backup address


```solidity
function emergencyBackupAddress() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|emergency backup address|


### strategyBalance

Gets strategy balance


```solidity
function strategyBalance(IBaseStrategy strategy) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Strategy balance in the vault|


### strategySharePercent

Gets strategy allocation percentage


```solidity
function strategySharePercent(IBaseStrategy strategy) external view returns (uint16);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint16`|Allocation percentage in basis points|


### maxWithdraw

Maximum amount of assets that can be withdrawn by owner


```solidity
function maxWithdraw(address owner) external view override returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|Owner of share tokens|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Maximum amount of assets that can be withdrawn|


### maxRedeem

Maximum amount of shares that can be redeemed by owner


```solidity
function maxRedeem(address owner) external view override returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|Owner of share tokens|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Maximum amount of shares that can be redeemed|


### totalAssets

Calculates total assets in the vault


```solidity
function totalAssets() external view override returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Total amount of assets|


## Events
### StrategyAdded
Event emitted when strategy is added


```solidity
event StrategyAdded(address indexed strategy);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`address`|Address of the strategy|

### StrategyMigrated
Event emitted when strategy is migrated


```solidity
event StrategyMigrated(address indexed oldVersion, address indexed newVersion);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`oldVersion`|`address`|Address of the old strategy|
|`newVersion`|`address`|Address of the new strategy|

### StrategyRemoved
Event emitted when strategy is removed


```solidity
event StrategyRemoved(address indexed strategy, uint256 totalAssets);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`address`|Address of the strategy|
|`totalAssets`|`uint256`|Amount of assets withdrawn|

### UpdateWithdrawalQueue
Event emitted when withdrawal queue is updated


```solidity
event UpdateWithdrawalQueue(IBaseStrategy[MAXIMUM_STRATEGIES] queue);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`queue`|`IBaseStrategy[MAXIMUM_STRATEGIES]`|New withdrawal queue|

### UpdateStrategySharePercent
Event emitted when strategy share percentage is updated


```solidity
event UpdateStrategySharePercent(address indexed strategy, uint256 newPercent);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`address`|Address of the strategy|
|`newPercent`|`uint256`|New allocation percentage|

### UpdatePerformanceFee
Event emitted when strategy performance fee is updated


```solidity
event UpdatePerformanceFee(address indexed strategy, uint16 indexed newFee);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`address`|Address of the strategy|
|`newFee`|`uint16`|New performance fee|

### UpdateManagementFee
Event emitted when management fee is updated


```solidity
event UpdateManagementFee(uint16 indexed fee);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fee`|`uint16`|New management fee|

### UpdateManagementRecipient
Event emitted when fee recipient is updated


```solidity
event UpdateManagementRecipient(address indexed recipient);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|New fee recipient address|

### UpdateEmergencyBackupAddress
Event emitted when fee emergencyBackupAddress is updated


```solidity
event UpdateEmergencyBackupAddress(address indexed backupAddress);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`backupAddress`|`address`|New emergency backup address|

### UpdateStrategyInfo
Event emitted when strategy info is updated


```solidity
event UpdateStrategyInfo(IBaseStrategy indexed strategy, uint256 newBalance);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy address|
|`newBalance`|`uint256`|New strategy balance|

### Reported
Event emitted when strategy report is generated


```solidity
event Reported(uint256 profit, uint256 loss, uint256 managementFees, uint256 performanceFees);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`profit`|`uint256`|Profit amount|
|`loss`|`uint256`|Loss amount|
|`managementFees`|`uint256`|Management fees charged|
|`performanceFees`|`uint256`|Performance fees charged|

## Errors
### ZeroAddress

```solidity
error ZeroAddress();
```

### UnsupportedIBaseStrategy

```solidity
error UnsupportedIBaseStrategy();
```

### IncorrectMin

```solidity
error IncorrectMin();
```

### IncorrectMax

```solidity
error IncorrectMax();
```

### InvalidAssetToken

```solidity
error InvalidAssetToken(IBaseStrategy strategy);
```

### InvalidVault

```solidity
error InvalidVault(IBaseStrategy strategy);
```

### IsPaused

```solidity
error IsPaused(IBaseStrategy strategy);
```

### NotPaused

```solidity
error NotPaused(IBaseStrategy strategy);
```

### OutOfLimitStrategies

```solidity
error OutOfLimitStrategies();
```

### StrategyExists

```solidity
error StrategyExists(IBaseStrategy strategy);
```

### StrategyNotExists

```solidity
error StrategyNotExists(IBaseStrategy strategy);
```

