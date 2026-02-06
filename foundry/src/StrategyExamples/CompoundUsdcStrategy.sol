// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {BaseStrategy} from "../BaseStrategy.sol";
import {IComet, ICometRewards} from "../interfaces/IComet.sol";
import {IUniswapV2Router} from "../interfaces/IUniswapV2Router.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PriceGetter} from "../extentions/PriceGetter.sol";

/**
 * @title Compound USDC Strategy
 * @notice Strategy for providing USDC liquidity to Compound V3 protocol
 * @dev Earns interest on USDC deposits and collects COMP rewards, swapping them to USDC
 */
contract CompoundUsdcStrategy is BaseStrategy {
    using SafeERC20 for IERC20;
    using PriceGetter for address;

    uint16 private constant MAX_BPS = 10_000;
    uint16 private constant MIN_BPS = 1;

    /// @notice ADDRESS_AGGREGATOR_V3 chainlink
    address public immutable ADDRESS_AGGREGATOR_V3;
    /// @notice Compound V3 Comet lending protocol contract
    IComet private immutable COMET;
    /// @notice Compound V3 Rewards contract for COMP distribution
    ICometRewards public immutable COMET_REWARD;
    /// @notice Uniswap V2 Router for swapping COMP to USDC
    address public immutable UNISWAP_ROUTER;
    /// @notice Address of the COMP reward token
    address public immutable COMP;
    /// @notice Max difference between AddressAggregatorV3.latestRoundData.updatedAt and now
    uint96 public updateMaxTime = 1 hours;
    /// @notice Deadline duration for Uniswap swaps, by default is 1 hour
    uint96 public swapDeadline = 1 hours;
    /// @notice Slippage tolerance in basis points, by default is 0,5%
    uint16 public slippageBps = 50;
    /// @notice Minimum swap amount in USDC to trigger swap, by default is 2000e18
    uint256 public minSwapAmount = 2000e18;

    /**
     * @notice Initializes the Compound USDC strategy
     * @dev Sets up Compound V3 integration and approves tokens for protocol interactions
     * @param comet_ Address of the Compound V3 Comet contract
     * @param token_ Address of the base asset (USDC)
     * @param name_ Strategy name for identification
     * @param vault_ Address of the vault this strategy serves
     * @param cometRewards_ Address of Compound V3 Rewards contract
     * @param rewardToken_ Address of the COMP reward token
     * @param uniswapRouter_ Address of Uniswap V2 Router
     * @param addressAggregatorV3_ Address of Chainlink AddressAggregatorV3
     */
    constructor(
        address comet_,
        address token_,
        string memory name_,
        address vault_,
        address cometRewards_,
        address rewardToken_,
        address uniswapRouter_,
        address addressAggregatorV3_
    ) BaseStrategy(token_, name_, vault_) {
        require(comet_ != address(0), ZeroAddress());
        require(cometRewards_ != address(0), ZeroAddress());
        require(rewardToken_ != address(0), ZeroAddress());
        require(uniswapRouter_ != address(0), ZeroAddress());
        require(addressAggregatorV3_ != address(0), ZeroAddress());

        COMET = IComet(comet_);
        COMET_REWARD = ICometRewards(cometRewards_);
        COMP = rewardToken_;
        UNISWAP_ROUTER = uniswapRouter_;
        ADDRESS_AGGREGATOR_V3 = addressAggregatorV3_;

        address token = COMET.baseToken();
        require(token == token_, InsufficientAssetsToken());

        IERC20(token_).forceApprove(comet_, type(uint256).max);
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
     * @notice Withdraws assets from Compound when needed
     * @dev Claims rewards, swaps to USDC, then withdraws from Compound if needed
     * @param _amount Amount of assets requested for withdrawal
     * @return The actual amount withdrawn
     */
    function _pull(uint256 _amount) internal virtual override returns (uint256) {
        uint256 balanceBefore = IERC20(_asset).balanceOf(address(this));

        if (_amount > balanceBefore) {
            _claimRewards();
            _swapRewardsToAsset();

            uint256 balance = COMET.balanceOf(address(this));
            if (_amount > balance) _amount = balance;

            COMET.withdraw(address(_asset), _amount);
        }

        uint256 balanceAfter = IERC20(_asset).balanceOf(address(this));

        return balanceAfter - balanceBefore;
    }
    /**
     * @notice Deposits assets into Compound V3
     * @param _amount Amount of assets to deposit
     */

    function _push(uint256 _amount) internal virtual override {
        _asset.forceApprove(address(COMET), _amount);
        COMET.supply(address(_asset), _amount);
    }

    /**
     * @notice Calculates total assets managed by the strategy
     * @dev Returns the balance of supplied assets in Compound (in USDC terms)
     * @return _totalAssets Total value of assets in USDC terms
     */
    function _harvestAndReport() internal virtual override returns (uint256 _totalAssets) {
        _claimRewards();
        _swapRewardsToAsset();

        uint256 assetBalance = IERC20(_asset).balanceOf(address(this));
        if (assetBalance > 0) {
            _push(assetBalance);
        }

        return COMET.balanceOf(address(this));
    }

    /**
     * @notice Claims COMP rewards from Compound V3
     * @dev Uses try-catch to handle cases where claim might fail
     * @notice `shouldAccrue` parameter is set to true to update interest before claiming
     */
    function _claimRewards() internal {
        // В Compound v3 награды через отдельный контракт
        try COMET_REWARD.claim(address(COMET), address(this), true) {} catch {}
    }

    /**
     * @notice Swaps COMP rewards to the base asset (USDC)
     * @dev Uses Uniswap V2 with a fixed path: COMP → USDC
     * @notice Uses 0 minimum output - accepting any exchange rate
     */
    function _swapRewardsToAsset() internal {
        uint256 rewardBalance = IERC20(COMP).balanceOf(address(this));
        if (rewardBalance == 0) return;

        uint256 expectedAmount = ADDRESS_AGGREGATOR_V3.getConversionPrice(updateMaxTime, rewardBalance);

        uint256 amountOutMin = (expectedAmount * (MAX_BPS - slippageBps)) / MAX_BPS;
        require(minSwapAmount >= amountOutMin, LessThanMinimumSwapAmount(amountOutMin));

        address[] memory path = new address[](2);
        path[0] = COMP;
        path[1] = address(_asset);

        uint256[] memory amounts = IUniswapV2Router(UNISWAP_ROUTER)
            .swapExactTokensForTokens(rewardBalance, amountOutMin, path, address(this), block.timestamp + swapDeadline);

        emit SwapExecuted(rewardBalance, amounts[1], amountOutMin);
    }

    /**
     * @notice Manually trigger reward harvesting and swapping
     * @dev Claims COMP rewards and swaps them to USDC immediately
     * @custom:role KEEPER_ROLE Only callable by keepers
     */
    function harvest() external onlyRole(KEEPER_ROLE) {
        _claimRewards();
        _swapRewardsToAsset();
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
