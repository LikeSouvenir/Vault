# BaseStrategy
[Git Source](https://github.com/LikeSouvenir/Vault/blob/8ed516f562cdb60c3e34b4e86693fe2158400602/src/BaseStrategy.sol)

**Inherits:**
[IBaseStrategy](/src/interfaces/IBaseStrategy.sol/interface.IBaseStrategy.md), ReentrancyGuard, AccessControl

**Title:**
Base Abstract Strategy Contract

All concrete strategies should inherit from this contract and implement virtual functions


## State Variables
### _vault
Vault address

default manager/keeper


```solidity
address internal immutable _vault
```


### _asset
Underlying asset of the strategy


```solidity
IERC20 internal immutable _asset
```


### _lastTotalAssets
Last recorded total asset balance


```solidity
uint256 private _lastTotalAssets
```


### _name
Strategy name


```solidity
string private _name
```


### _isPaused
Strategy pause flag


```solidity
bool internal _isPaused
```


### KEEPER_ROLE
Keeper role (bot/operator)


```solidity
bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE")
```


## Functions
### constructor

Creates a new base strategy

**Notes:**
- requires: assetToken_ must not be zero address

- requires: vault_ must not be zero address


```solidity
constructor(address assetToken_, string memory name_, address vault_) ;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assetToken_`|`address`|Address of the underlying asset|
|`name_`|`string`|Strategy name|
|`vault_`|`address`|Vault address|


### _pull

Withdraw assets from strategy (internal implementation)

Must be implemented in derived contracts


```solidity
function _pull(uint256 amount) internal virtual returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|Amount of assets to withdraw|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Actual amount withdrawn|


### _push

Deposit assets into strategy (internal implementation)

Must be implemented in derived contracts


```solidity
function _push(uint256 amount) internal virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|Amount of assets to deposit|


### _harvestAndReport

Harvest profits and report balance (internal implementation)

Must be implemented in derived contracts


```solidity
function _harvestAndReport() internal virtual returns (uint256 _totalAssets);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_totalAssets`|`uint256`|Current total asset balance in strategy|


### supportsInterface

Returns true if this contract implements the interface defined by
`interfaceId`. See the corresponding
https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
to learn more about how these ids are created.
This function call must use less than 30 000 gas.


```solidity
function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, IERC165) returns (bool);
```

### rebalanceAndReport

Call rebalance and report from vault

**Notes:**
- modifier: onlyRole(KEEPER_ROLE)

- modifier: nonReentrant Reentrancy protection


```solidity
function rebalanceAndReport()
    external
    onlyRole(KEEPER_ROLE)
    returns (uint256 profit, uint256 loss, uint256 balance);
```

### push

Deposit assets into strategy

**Notes:**
- modifier: onlyRole(DEFAULT_ADMIN_ROLE) Only administrator

- modifier: nonReentrant Reentrancy protection

- emits: Push


```solidity
function push(uint256 amount) external virtual onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|Amount of assets to deposit|


### pull

Withdraw assets from strategy

**Notes:**
- modifier: onlyRole(DEFAULT_ADMIN_ROLE) Only administrator

- modifier: nonReentrant Reentrancy protection

- requires: Requested amount must not exceed available balance

- emits: Pull


```solidity
function pull(uint256 amount) external virtual onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant returns (uint256 value);
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

**Notes:**
- modifier: nonReentrant Reentrancy protection

- modifier: onlyRole(DEFAULT_ADMIN_ROLE) Only administrator

- emits: Report


```solidity
function report()
    external
    virtual
    nonReentrant
    onlyRole(DEFAULT_ADMIN_ROLE)
    returns (uint256 profit, uint256 loss);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`profit`|`uint256`|Profit since last report|
|`loss`|`uint256`|Loss since last report|


### takeAndClose

Withdraw all assets and close strategy

**Note:**
modifier: onlyRole(DEFAULT_ADMIN_ROLE) Only administrator


```solidity
function takeAndClose() external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256 amount);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|Amount of assets withdrawn|


### emergencyWithdraw

Pauses the strategy, withdraws all assets to contract

**Notes:**
- modifier: onlyRole(DEFAULT_ADMIN_ROLE) Only administrator

- emits: EmergencyWithdraw


```solidity
function emergencyWithdraw() external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256 amount);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|Amount of assets withdrawn|


### _emergencyWithdraw


```solidity
function _emergencyWithdraw() internal returns (uint256 amount);
```

### pause

Pauses the strategy, withdraws all assets to contract

**Notes:**
- modifier: onlyRole(DEFAULT_ADMIN_ROLE) Only administrator

- emits: StrategyPaused


```solidity
function pause() public onlyRole(DEFAULT_ADMIN_ROLE);
```

### unpause

Resume strategy operation

**Notes:**
- modifier: onlyRole(DEFAULT_ADMIN_ROLE) Only administrator

- emits: StrategyUnpaused


```solidity
function unpause() external onlyRole(DEFAULT_ADMIN_ROLE);
```

### isPaused

Check if strategy is paused


```solidity
function isPaused() external view virtual returns (bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true if strategy is paused|


### asset

Get underlying asset address


```solidity
function asset() external view virtual returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|Asset address|


### vault

Get vault address


```solidity
function vault() external view virtual returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|Vault address|


### lastTotalAssets

Get last recorded balance


```solidity
function lastTotalAssets() external view virtual returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Asset balance|


### name

Get strategy name


```solidity
function name() external view virtual returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|Strategy name|


