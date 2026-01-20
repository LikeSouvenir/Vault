// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {BaseStrategy} from "../BaseStrategy.sol";
import {IComet, ICometRewards} from "../interfaces/IComet.sol";
import {IUniswapV2Router} from "../interfaces/IUniswapV2Router.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Compound USDC Strategy
 * @notice Strategy for providing USDC liquidity to Compound V3 protocol
 * @dev Earns interest on USDC deposits and collects COMP rewards, swapping them to USDC
 */
contract CompoundUsdcStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    /// @notice Compound V3 Comet lending protocol contract
    IComet private immutable comet;
    /// @notice Compound V3 Rewards contract for COMP distribution
    ICometRewards public immutable cometReward;
    /// @notice Address of the COMP reward token
    address public immutable comp;
    /// @notice Uniswap V2 Router for swapping COMP to USDC
    address public immutable uniswapRouter;
    /// @notice Deadline duration for Uniswap swaps (default: 1 hour)
    uint256 public swapDeadline = 1 hours;

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
     */
    constructor(
        address comet_,
        address token_,
        string memory name_,
        address vault_,
        address cometRewards_,
        address rewardToken_,
        address uniswapRouter_
    ) BaseStrategy(token_, name_, vault_) {
        require(comet_ != address(0), "zero comet address");
        require(cometRewards_ != address(0), "zero comet rewards address");
        require(rewardToken_ != address(0), "zero reward token address");
        require(uniswapRouter_ != address(0), "zero uniswap router");

        comet = IComet(comet_);
        cometReward = ICometRewards(cometRewards_);
        comp = rewardToken_;
        uniswapRouter = uniswapRouter_;

        address token = comet.baseToken();
        require(token == token_, "invalid token");

        IERC20(token_).forceApprove(comet_, type(uint256).max);
        IERC20(rewardToken_).forceApprove(uniswapRouter_, type(uint256).max);
    }

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

            uint256 balance = comet.balanceOf(address(this));
            if (_amount > balance) _amount = balance;

            comet.withdraw(address(_asset), _amount);
        }

        uint256 balanceAfter = IERC20(_asset).balanceOf(address(this));

        return balanceAfter - balanceBefore;
    }
    /**
     * @notice Deposits assets into Compound V3
     * @param _amount Amount of assets to deposit
     */

    function _push(uint256 _amount) internal virtual override {
        require(_asset.approve(address(comet), _amount), "approve failed");
        comet.supply(address(_asset), _amount);
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

        return comet.balanceOf(address(this));
    }

    /**
     * @notice Claims COMP rewards from Compound V3
     * @dev Uses try-catch to handle cases where claim might fail
     * @notice `shouldAccrue` parameter is set to true to update interest before claiming
     */
    function _claimRewards() internal {
        // В Compound v3 награды через отдельный контракт
        // Для примера, исполльзуем метод claim
        try cometReward.claim(address(comet), address(this), true) {} catch {}
    }

    /**
     * @notice Swaps COMP rewards to the base asset (USDC)
     * @dev Uses Uniswap V2 with a fixed path: COMP → USDC
     * @notice Uses 0 minimum output - accepting any exchange rate
     */
    function _swapRewardsToAsset() internal {
        uint256 rewardBalance = IERC20(comp).balanceOf(address(this));
        if (rewardBalance > 0) {
            address[] memory path = new address[](2);
            path[0] = comp;
            path[1] = address(_asset);

            IUniswapV2Router(uniswapRouter)
                .swapExactTokensForTokens(
                    rewardBalance,
                    0, // любой курс
                    path,
                    address(this),
                    block.timestamp + swapDeadline
                );
        }
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
     * @param delay New deadline duration in seconds
     * @custom:role DEFAULT_ADMIN_ROLE Only callable by admin
     */
    function setSwapDeadline(uint256 delay) external onlyRole(DEFAULT_ADMIN_ROLE) {
        swapDeadline = delay;
    }
}
