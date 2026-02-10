# Vault
[Git Source](https://github.com/LikeSouvenir/Vault/blob/36fdd71da90fb692ff334a0a992d2c455d783bcd/src/Vault.sol)

**Inherits:**
[IVault](/src/interfaces/IVault.sol/interface.IVault.md), ERC4626, AccessControl, ReentrancyGuard

**Title:**
Vault ERC-4626 with Strategy Support

Extends the ERC-4626 standard to create a managed asset vault with a strategy system

The contract allows adding strategies, managing asset allocation, and automatically charging fees


## State Variables
### BPS
Basis for percentage calculations (100% = 10,000)


```solidity
uint256 internal constant BPS = 10_000
```


### DEFAULT_PERFORMANCE_FEE
Default performance fee (1%)


```solidity
uint16 internal constant DEFAULT_PERFORMANCE_FEE = 100
```


### DEFAULT_MANAGEMENT_FEE
Default management fee (1%)


```solidity
uint16 internal constant DEFAULT_MANAGEMENT_FEE = 100
```


### MAX_PERCENT
Maximum percentage (100%)


```solidity
uint16 internal constant MAX_PERCENT = 10_000
```


### MAXIMUM_STRATEGIES
Maximum number of strategies that can be added


```solidity
uint256 internal constant MAXIMUM_STRATEGIES = 20
```


### MIN_PERCENT
Minimum percentage (0.01%)


```solidity
uint16 internal constant MIN_PERCENT = 1
```


### SECONDS_PER_YEAR
Seconds per year for max profit unlocking time.

365.2425 days


```solidity
uint256 internal constant SECONDS_PER_YEAR = 31_556_952
```


### EMERGENCY_ADMIN_ROLE
emergency role


```solidity
bytes32 public constant EMERGENCY_ADMIN_ROLE = keccak256("EMERGENCY_ADMIN_ROLE")
```


### KEEPER_ROLE
Keeper role (bot/operator)


```solidity
bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE")
```


### PAUSER_ROLE
Pauser role

can pause & unpause strategies


```solidity
bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE")
```


### _managementFee
The percent in basis points of profit that is charged as a fee.


```solidity
uint16 private _managementFee
```


### _feeRecipient
The address to pay the `performanceFee` to.


```solidity
address private _feeRecipient
```


### _emergencyBackupAddress
The address to which the entire balance will be transferred when call 'emergencyExit'.


```solidity
address private _emergencyBackupAddress
```


### _withdrawalQueue
Withdrawal queue for strategies


```solidity
IBaseStrategy[MAXIMUM_STRATEGIES] private _withdrawalQueue
```


### _strategyInfoMap
Mapping of strategy information


```solidity
mapping(IBaseStrategy => StrategyInfo) private _strategyInfoMap
```


## Functions
### constructor

Creates a new Vault contract

Initializes an ERC-4626 vault with given parameters

**Notes:**
- requires: feeRecipient_ must not be zero address

- requires: assetToken_ must not be zero address

- requires: manager_ must not be zero address


```solidity
constructor(
    IERC20 assetToken_,
    string memory nameShare_,
    string memory symbolShare_,
    address manager_,
    address feeRecipient_,
    address emergencyBackupAddress_
) ERC4626(assetToken_) ERC20(nameShare_, symbolShare_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assetToken_`|`IERC20`|Address of the underlying asset|
|`nameShare_`|`string`|Name of the share token|
|`symbolShare_`|`string`|Symbol of the share token|
|`manager_`|`address`|Manager (administrator) address|
|`feeRecipient_`|`address`|Fee recipient address|
|`emergencyBackupAddress_`|`address`||


### supportsInterface

Returns true if this contract implements the interface defined by
`interfaceId`. See the corresponding
https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
to learn more about how these ids are created.
This function call must use less than 30 000 gas.


```solidity
function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, IERC165) returns (bool);
```

### supportIBaseStrategyInterface

Internal function to check IBaseStrategy support


```solidity
modifier supportIBaseStrategyInterface(IERC165 strategy) ;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IERC165`|Strategy to check|


### _supportIBaseStrategyInterface

Internal function to check IBaseStrategy support


```solidity
function _supportIBaseStrategyInterface(IERC165 strategy) internal view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IERC165`|Strategy to check|


### checkBorderBps

Modifier to check if percentage is within bounds


```solidity
modifier checkBorderBps(uint16 num) ;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`num`|`uint16`|Percentage value|


### _checkBorderBps

Internal function to check percentage bounds


```solidity
function _checkBorderBps(uint16 num) internal pure;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`num`|`uint16`|Percentage value|


### checkAsset

Modifier to check if strategy uses correct asset


```solidity
modifier checkAsset(IBaseStrategy strategy) ;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy to check|


### _checkAsset

Internal function to check asset compatibility


```solidity
function _checkAsset(IBaseStrategy strategy) internal view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy to check|


### checkVault

Modifier to check if strategy references correct vault


```solidity
modifier checkVault(IBaseStrategy strategy) ;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy to check|


### _checkVault

Internal function to check vault reference


```solidity
function _checkVault(IBaseStrategy strategy) internal view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy to check|


### notPaused

Modifier to check if strategy is not paused


```solidity
modifier notPaused(IBaseStrategy strategy) ;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy to check|


### _notPaused

Internal function to check pause status


```solidity
function _notPaused(IBaseStrategy strategy) internal view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy to check|


### notExists

Modifier to check notExists strategy status


```solidity
modifier notExists(IBaseStrategy strategy) ;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy to check|


### _notExists

Internal function to check notExists strategy status


```solidity
function _notExists(IBaseStrategy strategy) internal view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy to check|


### exists

Modifier to check exists strategy status


```solidity
modifier exists(IBaseStrategy strategy) ;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy to check|


### _exists

Internal function to check exists strategy


```solidity
function _exists(IBaseStrategy strategy) internal view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy to check|


### add

Adds a new strategy to the vault

Strategy must be configured with correct assets and reference to this vault

**Notes:**
- modifier: onlyRole(DEFAULT_ADMIN_ROLE) Only administrator

- modifier: supportIBaseStrategyInterface Strategy must implement IBaseStrategy

- modifier: checkAsset Strategy must use the same asset

- modifier: checkVault Strategy must reference this vault

- requires: Must have available slot for new strategy

- requires: Strategy must not already exist

- requires: Strategy allowance must be type(uint256).max

- emits: StrategyAdded


```solidity
function add(IBaseStrategy newStrategy, uint16 sharePercent)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    supportIBaseStrategyInterface(IERC165(newStrategy))
    checkAsset(newStrategy)
    checkVault(newStrategy)
    notExists(newStrategy);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newStrategy`|`IBaseStrategy`|Address of the new strategy|
|`sharePercent`|`uint16`|Asset allocation percentage in basis points (0.01% = 1) for the strategy|


### migrate

Migrates assets from old strategy to new strategy

Completely transfers balance and settings from old to new strategy

**Notes:**
- modifier: onlyRole(DEFAULT_ADMIN_ROLE) Only administrator

- modifier: supportIBaseStrategyInterface Strategy must implement IBaseStrategy

- modifier: checkAsset New strategy must use the same asset

- modifier: checkVault New strategy must reference this vault

- requires: New strategy must not already exist

- emits: StrategyMigrated


```solidity
function migrate(IBaseStrategy oldStrategy, IBaseStrategy newStrategy)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    supportIBaseStrategyInterface(IERC165(newStrategy))
    checkAsset(newStrategy)
    checkVault(newStrategy)
    notExists(newStrategy)
    exists(oldStrategy);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`oldStrategy`|`IBaseStrategy`|Old strategy to migrate from|
|`newStrategy`|`IBaseStrategy`|New strategy to migrate to|


### withdraw

**Note:**
modifier: nonReentrant Reentrancy protection


```solidity
function withdraw(uint256 assets, address receiver, address owner)
    public
    override(ERC4626, IERC4626)
    nonReentrant
    returns (uint256);
```

### redeem

**Note:**
modifier: nonReentrant Reentrancy protection


```solidity
function redeem(uint256 shares, address receiver, address owner)
    public
    override(ERC4626, IERC4626)
    nonReentrant
    returns (uint256);
```

### _withdraw

Internal withdrawal function


```solidity
function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
    internal
    override;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`caller`|`address`|Address initiating withdrawal|
|`receiver`|`address`|Address receiving assets|
|`owner`|`address`|Address owning shares|
|`assets`|`uint256`|Amount of assets to withdraw|
|`shares`|`uint256`|Amount of shares to burn|


### report

Reports on strategy performance (called by keeper)

Calculates profit/loss and charges fees

**Notes:**
- modifier: onlyRole(KEEPER_ROLE) Only keeper

- emits: Reported


```solidity
function report(IBaseStrategy strategy)
    external
    onlyRole(KEEPER_ROLE)
    returns (uint256 profit, uint256 loss, uint256 balance);
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


### _report

Internal function to process strategy report


```solidity
function _report(IBaseStrategy strategy, bool update)
    internal
    notPaused(strategy)
    returns (uint256 profit, uint256 loss, uint256 balance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy to report on|
|`update`|`bool`||


### rebalance

Rebalances a strategy (called by keeper)

Adjusts strategy balance to match its sharePercent

**Notes:**
- modifier: onlyRole(KEEPER_ROLE) Only keeper

- modifier: notPaused Strategy must not be paused

- requires: Strategy must exist

- emits: UpdateStrategyInfo


```solidity
function rebalance(IBaseStrategy strategy) external onlyRole(KEEPER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy to rebalance|


### _rebalance

Internal function to rebalance strategy


```solidity
function _rebalance(IBaseStrategy strategy) internal notPaused(strategy) exists(strategy);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy to rebalance|


### remove

Removes a strategy from the vault

Withdraws all assets from the strategy and removes it from the queue

**Notes:**
- modifier: onlyRole(DEFAULT_ADMIN_ROLE) Only administrator

- requires: Strategy must exist

- emits: StrategyRemoved


```solidity
function remove(IBaseStrategy strategy)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    exists(strategy)
    returns (uint256 amountAssets);
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

Defines the order in which strategies will be used for withdrawals

**Notes:**
- modifier: onlyRole(DEFAULT_ADMIN_ROLE) Only administrator

- requires: All strategies in queue must exist

- emits: UpdateWithdrawalQueue


```solidity
function setWithdrawalQueue(IBaseStrategy[MAXIMUM_STRATEGIES] memory queue) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`queue`|`IBaseStrategy[MAXIMUM_STRATEGIES]`|New strategy queue|


### setSharePercent

Sets allocation percentage for a strategy

**Notes:**
- modifier: onlyRole(DEFAULT_ADMIN_ROLE) Only administrator

- modifier: checkBorderBps Percentage must be within valid bounds

- requires: Sum of all percentages must not exceed 100%

- emits: UpdateStrategySharePercent


```solidity
function setSharePercent(IBaseStrategy strategy, uint16 sharePercent)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
    checkBorderBps(sharePercent);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy|
|`sharePercent`|`uint16`|New allocation percentage|


### setPerformanceFee

Sets performance fee for a strategy

**Notes:**
- modifier: onlyRole(DEFAULT_ADMIN_ROLE) Only administrator

- modifier: checkBorderBps Fee must be within valid bounds

- emits: UpdatePerformanceFee


```solidity
function setPerformanceFee(IBaseStrategy strategy, uint16 newFee)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    checkBorderBps(newFee);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy|
|`newFee`|`uint16`|New fee in basis points|


### setManagementFee

Sets management fee for the entire vault

**Notes:**
- modifier: onlyRole(DEFAULT_ADMIN_ROLE) Only administrator

- modifier: checkBorderBps Fee must be within valid bounds

- emits: UpdateManagementFee


```solidity
function setManagementFee(uint16 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) checkBorderBps(newFee);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newFee`|`uint16`|New fee in basis points|


### setFeeRecipient

Sets fee recipient address

**Notes:**
- modifier: onlyRole(DEFAULT_ADMIN_ROLE) Only administrator

- requires: recipient must not be zero address

- emits: UpdateManagementRecipient


```solidity
function setFeeRecipient(address recipient) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|New recipient address|


### setEmergencyBackupAddress

Sets emergency backup address

**Notes:**
- modifier: onlyRole(DEFAULT_ADMIN_ROLE) Only administrator

- requires: emergencyBackupAddress must not be zero address

- emits: UpdateEmergencyBackupAddress


```solidity
function setEmergencyBackupAddress(address backupAddress) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`backupAddress`|`address`|New backup address|


### emergencyWithdraw

Emergency withdraw from strategy (admin only)

Used in case of strategy issues

**Notes:**
- modifier: onlyRole(EMERGENCY_ADMIN_ROLE) Only emergency administrator

- emits: EmergencyWithdraw (in strategy)


```solidity
function emergencyWithdraw(IBaseStrategy strategy) public onlyRole(EMERGENCY_ADMIN_ROLE) returns (uint256 amount);
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

**Notes:**
- modifier: onlyRole(PAUSER_ROLE) Only pauser manager

- modifier: notPaused Strategy must not already be paused


```solidity
function pause(IBaseStrategy strategy) external onlyRole(PAUSER_ROLE) notPaused(strategy);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy to pause|


### unpause

Unpauses a strategy

**Notes:**
- modifier: onlyRole(PAUSER_ROLE) Only pauser manager

- requires: Strategy must be paused


```solidity
function unpause(IBaseStrategy strategy) external onlyRole(PAUSER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy to unpause|


### strategyGrantRole

GrantRole in a strategy


```solidity
function strategyGrantRole(IBaseStrategy strategy, bytes32 role, address account)
    external
    onlyRole(DEFAULT_ADMIN_ROLE);
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
function strategyRevokeRole(IBaseStrategy strategy, bytes32 role, address account)
    public
    onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IBaseStrategy`|Strategy  where revoked role|
|`role`|`bytes32`|Role to be revoked|
|`account`|`address`|Account revoked role|


### maxWithdraw

Takes into account liquidity in vault and strategies


```solidity
function maxWithdraw(address owner) public view override(ERC4626, IVault) returns (uint256);
```

### maxRedeem

Takes into account liquidity in vault and strategies


```solidity
function maxRedeem(address owner) public view override(ERC4626, IVault) returns (uint256);
```

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


### totalAssets

Includes balance in vault itself and all active strategies


```solidity
function totalAssets() public view override(ERC4626, IVault) returns (uint256 total);
```

### strategyBalance

Gets strategy balance


```solidity
function strategyBalance(IBaseStrategy strategy) public view returns (uint256);
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


## Structs
### StrategyInfo
Strategy information structure


```solidity
struct StrategyInfo {
    uint256 balance;
    uint96 lastTakeTime;
    uint16 sharePercent;
    uint16 performanceFee; // The percent in basis points of profit that is charged as a fee.
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`balance`|`uint256`|Current strategy balance in the vault|
|`lastTakeTime`|`uint96`|Time of last management fee collection|
|`sharePercent`|`uint16`|Percentage of total deposits allocated to the strategy|
|`performanceFee`|`uint16`|Performance fee in basis points|

