# IUniswapV2Router
[Git Source](https://github.com/LikeSouvenir/Vault/blob/8ed516f562cdb60c3e34b4e86693fe2158400602/src/interfaces/IUniswapV2Router.sol)

**Title:**
Uniswap V2 Router Interface

Interface for Uniswap V2 Router for token swaps

Provides functions for swapping tokens through Uniswap V2 liquidity pools


## Functions
### swapExactTokensForTokens

Swaps an exact amount of input tokens for as many output tokens as possible

Swaps along the specified path, reverting if output amount is below minimum


```solidity
function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
) external returns (uint256[] memory amounts);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountIn`|`uint256`|The exact amount of input tokens to send|
|`amountOutMin`|`uint256`|The minimum amount of output tokens to receive (slippage protection)|
|`path`|`address[]`|An array of token addresses representing the swap path path[0] = input token, path[path.length-1] = output token|
|`to`|`address`|The recipient address of the output tokens|
|`deadline`|`uint256`|Unix timestamp after which the transaction will revert|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amounts`|`uint256[]`|Array of amounts at each step of the swap path amounts[0] = amountIn, amounts[amounts.length-1] = amountOut|


