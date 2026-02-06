// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {BaseStrategy} from "../BaseStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV2Router} from "../interfaces/IUniswapV2Router.sol";
import {IPool, IRewardsController, IAToken} from "../interfaces/IAaveV3.sol";
import {PriceGetter} from "../extentions/PriceGetter.sol";

/**
 * @title Aave USDC Strategy
 * @notice Strategy for providing USDC liquidity to Aave V3 protocol
 * @dev Earns interest on USDC deposits and collects AAVE rewards, swapping them to USDC
 */
contract AaveUsdcStrategy is BaseStrategy {
    using SafeERC20 for IERC20;
    using PriceGetter for address;

    uint16 private constant MAX_BPS = 10_000;
    uint16 private constant MIN_BPS = 1;

    /// @notice ADDRESS_AGGREGATOR_V3 chainlink
    address public immutable ADDRESS_AGGREGATOR_V3;
    /// @notice Aave V3 Pool contract for lending operations
    IPool public immutable AAVE_POOL;
    /// @notice aUSDC token representing USDC deposits in Aave
    IAToken public immutable A_TOKEN;
    /// @notice Aave Rewards Controller for claiming incentive rewards
    IRewardsController public immutable REWARDS_CONTROLLER;
    /// @notice Address of the reward token (AAVE)
    address public immutable REWARD_TOKEN;
    /// @notice Uniswap V2 Router for swapping rewards to USDC
    address public immutable UNISWAP_V2_ROUTER;
    /// @notice Max difference between AddressAggregatorV3.latestRoundData.updatedAt and now
    uint96 public updateMaxTime = 1 hours;
    /// @notice Deadline duration for Uniswap swaps, by default is 1 hour
    uint96 public swapDeadline = 1 hours;
    /// @notice Slippage tolerance in basis points, by default is 0,5%
    uint16 public slippageBps = 50;
    /// @notice Minimum swap amount in USDC to trigger swap, by default is 2000e18
    uint256 public minSwapAmount = 2000e18;

    /**
     * @notice Initializes the Aave USDC strategy
     * @dev Sets up Aave V3 integration and approves tokens for protocol interactions
     * @param pool_ Address of the Aave V3 Pool contract
     * @param token_ Address of the base asset (USDC)
     * @param name_ Strategy name for identification
     * @param vault_ Address of the vault this strategy serves
     * @param aToken_ Address of the aUSDC token
     * @param rewardsController_ Address of Aave Rewards Controller
     * @param rewardToken_ Address of the reward token (AAVE)
     * @param uniswapRouter_ Address of Uniswap V2 Router
     * @param addressAggregatorV3_ Address of Chainlink AddressAggregatorV3
     */
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
    ) BaseStrategy(token_, name_, vault_) {
        require(pool_ != address(0), ZeroAddress());
        require(aToken_ != address(0), ZeroAddress());
        require(rewardsController_ != address(0), ZeroAddress());
        require(rewardToken_ != address(0), ZeroAddress());
        require(uniswapRouter_ != address(0), ZeroAddress());
        require(addressAggregatorV3_ != address(0), ZeroAddress());

        AAVE_POOL = IPool(pool_);
        A_TOKEN = IAToken(aToken_);
        REWARDS_CONTROLLER = IRewardsController(rewardsController_);
        REWARD_TOKEN = rewardToken_;
        UNISWAP_V2_ROUTER = uniswapRouter_;
        ADDRESS_AGGREGATOR_V3 = addressAggregatorV3_;

        require(A_TOKEN.UNDERLYING_ASSET_ADDRESS() == token_, InsufficientAssetsToken());

        IERC20(token_).forceApprove(pool_, type(uint256).max);
        IERC20(rewardToken_).forceApprove(uniswapRouter_, type(uint256).max);
    }

    error IncorrectMin();
    error IncorrectMax();
    error LessThanMinimumSwapAmount(uint256 currentAmount);
    error IncorrectMinTime();

    event SlippageUpdated(uint256 newSlippageBps);
    event MinSwapAmountUpdated(uint256 newMinAmount);
    event SwapExecuted(uint256 amountIn, uint256 amountOut, uint256 minAmountOut);

    /**
     * @notice Withdraws assets from Aave when needed
     * @dev If insufficient balance, claims rewards, swaps them, and withdraws from Aave
     * @param _amount Amount of assets requested for withdrawal
     * @return The actual amount withdrawn
     */
    function _pull(uint256 _amount) internal virtual override returns (uint256) {
        uint256 balanceBefore = IERC20(_asset).balanceOf(address(this));

        if (_amount > balanceBefore) {
            _claimAndSwapRewards();

            uint256 aBalance = A_TOKEN.balanceOf(address(this));
            uint256 toWithdraw = _amount - balanceBefore;

            if (toWithdraw > aBalance) {
                toWithdraw = aBalance;
            }

            if (toWithdraw > 0) {
                AAVE_POOL.withdraw(address(_asset), toWithdraw, address(this));
            }
        }

        uint256 balanceAfter = IERC20(_asset).balanceOf(address(this));
        return balanceAfter - balanceBefore;
    }

    /**
     * @notice Deposits assets into Aave V3
     * @param _amount Amount of assets to deposit
     */
    function _push(uint256 _amount) internal virtual override {
        _asset.forceApprove(address(A_TOKEN), _amount);
        AAVE_POOL.supply(address(_asset), _amount, address(this), 0);
    }

    /**
     * @notice Calculates total assets managed by the strategy
     * @dev Includes both USDC balance and aUSDC balance (converted to USDC)
     * @return _totalAssets Total value of assets in USDC terms
     */
    function _harvestAndReport() internal virtual override returns (uint256 _totalAssets) {
        _claimAndSwapRewards();

        uint256 assetBalance = IERC20(_asset).balanceOf(address(this));
        if (assetBalance > 0) {
            _push(assetBalance);
        }

        uint256 aTokenBalance = A_TOKEN.balanceOf(address(this));
        uint256 contractBalance = IERC20(_asset).balanceOf(address(this));

        return aTokenBalance + contractBalance;
    }

    /**
     * @notice Claims AAVE rewards and swaps them to USDC
     * @dev Internal function called during withdrawals and reporting
     */
    function _claimAndSwapRewards() internal {
        address[] memory assets = new address[](1);
        assets[0] = address(A_TOKEN);

        uint256 pendingRewards = REWARDS_CONTROLLER.getUserRewards(assets, address(this), REWARD_TOKEN);

        if (pendingRewards > 0) {
            REWARDS_CONTROLLER.claimRewards(assets, pendingRewards, address(this), REWARD_TOKEN);

            _swapRewardsToAsset();
        }
    }

    /**
     * @notice Swaps reward tokens to the base asset (USDC)
     * @dev Uses Uniswap V2 with a fixed path: AAVE to USDC
     */
    function _swapRewardsToAsset() internal {
        uint256 rewardBalance = IERC20(REWARD_TOKEN).balanceOf(address(this));
        if (rewardBalance == 0) return;

        uint256 expectedAmount = ADDRESS_AGGREGATOR_V3.getConversionPrice(updateMaxTime, rewardBalance);

        uint256 amountOutMin = (expectedAmount * (MAX_BPS - slippageBps)) / MAX_BPS;
        require(minSwapAmount >= amountOutMin, LessThanMinimumSwapAmount(amountOutMin));

        address[] memory path = new address[](2);
        path[0] = REWARD_TOKEN;
        path[1] = address(_asset);

        uint256[] memory amounts = IUniswapV2Router(UNISWAP_V2_ROUTER)
            .swapExactTokensForTokens(rewardBalance, amountOutMin, path, address(this), block.timestamp + swapDeadline);

        emit SwapExecuted(rewardBalance, amounts[1], amountOutMin);
    }

    /**
     * @notice Manually trigger reward harvesting
     * @dev Can be called by keeper to optimize gas costs
     * @custom:role KEEPER_ROLE Only callable by keepers
     */
    function harvest() external onlyRole(KEEPER_ROLE) {
        _claimAndSwapRewards();
    }

    /**
     * @notice Update swap deadline duration
     * @param newSwapDeadline New deadline duration in seconds
     * @custom:role DEFAULT_ADMIN_ROLE Only callable by admin
     */
    function setSwapDeadline(uint96 newSwapDeadline) external onlyRole(DEFAULT_ADMIN_ROLE) {
        swapDeadline = newSwapDeadline;
    }

    /**
     * @notice Updates the maximum time for price updates from aggregator
     * @dev Prevents using stale prices by ensuring updates occur within reasonable timeframes
     * @param newMaxTime New maximum update time in seconds
     * @custom:role DEFAULT_ADMIN_ROLE Only callable by admin
     */
    function setUpdateMaxTime(uint96 newMaxTime) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newMaxTime >= 1 hours, IncorrectMinTime());

        updateMaxTime = newMaxTime;
    }

    /**
     * @notice Updates the slippage tolerance for swaps, by default = 2000e18
     * @dev Prevents front-running and excessive price impact during COMP→USDC swaps
     * @param newSlippageBps New slippage tolerance in basis points (1-10000)
     * @custom:role DEFAULT_ADMIN_ROLE Only callable by admin
     */
    function setSlippageBps(uint16 newSlippageBps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newSlippageBps >= MIN_BPS, IncorrectMin());
        require(newSlippageBps <= MAX_BPS, IncorrectMax());

        slippageBps = newSlippageBps;

        emit SlippageUpdated(newSlippageBps);
    }

    /**
     * @notice Updates the minimum COMP amount to trigger a swap
     * @dev Prevents wasteful gas spending on small reward swaps
     * @param newMinAmount New minimum amount in USDC terms (18 decimals)
     * @custom:role DEFAULT_ADMIN_ROLE Only callable by admin
     */
    function setMinSwapAmount(uint256 newMinAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minSwapAmount = newMinAmount;

        emit MinSwapAmountUpdated(newMinAmount);
    }
}
