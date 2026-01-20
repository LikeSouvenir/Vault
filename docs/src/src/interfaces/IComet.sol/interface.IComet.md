# IComet
[Git Source](https://github.com/LikeSouvenir/Vault/blob/8ed516f562cdb60c3e34b4e86693fe2158400602/src/interfaces/IComet.sol)

**Title:**
Compound V3 (Comet) Core Interface

Interface for interacting with Compound V3 lending protocol

Main Comet protocol contract that handles supply, withdraw, and rate calculations


## Functions
### balanceOf

Gets the balance of an account in base token units

Returns the amount of base tokens that would be received if withdrawing all supplied assets


```solidity
function balanceOf(address account) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|The address of the account to query|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The balance of the account in base token units|


### supply

Supplies an asset to the protocol

Transfers asset from caller and credits account's balance


```solidity
function supply(address asset, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset to supply|
|`amount`|`uint256`|The amount of the asset to supply|


### withdraw

Withdraws an asset from the protocol

Debits account's balance and transfers asset to caller


```solidity
function withdraw(address asset, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset to withdraw|
|`amount`|`uint256`|The amount of the asset to withdraw|


### baseToken

Gets the address of the base token for this market

Base token is the primary asset (e.g., USDC for USDC market)


```solidity
function baseToken() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The address of the base token|


### getSupplyRate

Calculates the current supply rate based on utilization

Rate is returned as a per-second interest rate scaled by 1e18


```solidity
function getSupplyRate(uint256 utilization) external view returns (uint64);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`utilization`|`uint256`|The current utilization rate (0 to 1e18 scale)|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint64`|The supply rate per second (scaled by 1e18)|


### getBorrowRate

Calculates the current borrow rate based on utilization

Rate is returned as a per-second interest rate scaled by 1e18


```solidity
function getBorrowRate(uint256 utilization) external view returns (uint64);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`utilization`|`uint256`|The current utilization rate (0 to 1e18 scale)|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint64`|The borrow rate per second (scaled by 1e18)|


### totalSupply

Gets the total amount of assets supplied to the protocol

Returns total supply across all users in base token units


```solidity
function totalSupply() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The total supply amount in base token units|


### totalBorrow

Gets the total amount of assets borrowed from the protocol

Returns total borrow across all users in base token units


```solidity
function totalBorrow() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The total borrow amount in base token units|


### hasPermission

Checks if a manager has permission to act on behalf of an owner

Used for delegated account management


```solidity
function hasPermission(address owner, address manager) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|The address of the account owner|
|`manager`|`address`|The address being checked for permissions|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if manager has permission, false otherwise|


