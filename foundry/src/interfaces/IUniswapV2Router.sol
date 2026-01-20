// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

/**
 * @title Uniswap V2 Router Interface
 * @notice Interface for Uniswap V2 Router for token swaps
 * @dev Provides functions for swapping tokens through Uniswap V2 liquidity pools
 */
interface IUniswapV2Router {
    /**
     * @notice Swaps an exact amount of input tokens for as many output tokens as possible
     * @dev Swaps along the specified path, reverting if output amount is below minimum
     * @param amountIn The exact amount of input tokens to send
     * @param amountOutMin The minimum amount of output tokens to receive (slippage protection)
     * @param path An array of token addresses representing the swap path
     *              path[0] = input token, path[path.length-1] = output token
     * @param to The recipient address of the output tokens
     * @param deadline Unix timestamp after which the transaction will revert
     * @return amounts Array of amounts at each step of the swap path
     *         amounts[0] = amountIn, amounts[amounts.length-1] = amountOut
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}
