// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {BaseStrategy} from "../BaseStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV2Router} from "../interfaces/IUniswapV2Router.sol";
import {IPool, IRewardsController, IAToken} from "../interfaces/IAaveV3.sol";

/**
 * @title Aave USDC Strategy
 * @notice Strategy for providing USDC liquidity to Aave V3 protocol
 * @dev Earns interest on USDC deposits and collects AAVE rewards, swapping them to USDC
 */
contract AaveUsdcStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    /// @notice Aave V3 Pool contract for lending operations
    IPool public immutable aavePool;
    /// @notice aUSDC token representing USDC deposits in Aave
    IAToken public immutable aToken;
    /// @notice Aave Rewards Controller for claiming incentive rewards
    IRewardsController public immutable rewardsController;
    /// @notice Address of the reward token (AAVE)
    address public immutable rewardToken;
    /// @notice Uniswap V2 Router for swapping rewards to USDC
    address public immutable uniswapV2Router;
    /// @notice Deadline duration for Uniswap swaps (default: 1 hour)
    uint256 public swapDeadline = 1 hours;

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
     */
    constructor(
        address pool_,
        address token_,
        string memory name_,
        address vault_,
        address aToken_,
        address rewardsController_,
        address rewardToken_,
        address uniswapRouter_
    ) BaseStrategy(token_, name_, vault_) {
        require(pool_ != address(0), "zero pool address");
        require(aToken_ != address(0), "zero aToken address");
        require(rewardsController_ != address(0), "zero rewards controller");
        require(rewardToken_ != address(0), "zero reward token address");
        require(uniswapRouter_ != address(0), "zero uniswap router");

        aavePool = IPool(pool_);
        aToken = IAToken(aToken_);
        rewardsController = IRewardsController(rewardsController_);
        rewardToken = rewardToken_;
        uniswapV2Router = uniswapRouter_;

        require(aToken.UNDERLYING_ASSET_ADDRESS() == token_, "invalid aToken");

        IERC20(token_).forceApprove(pool_, type(uint256).max);
        IERC20(rewardToken_).forceApprove(uniswapRouter_, type(uint256).max);
    }

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

            uint256 aBalance = aToken.balanceOf(address(this));
            uint256 toWithdraw = _amount - balanceBefore;

            if (toWithdraw > aBalance) {
                toWithdraw = aBalance;
            }

            if (toWithdraw > 0) {
                aavePool.withdraw(address(_asset), toWithdraw, address(this));
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
        require(_asset.approve(address(aToken), _amount), "approve failed");
        aavePool.supply(address(_asset), _amount, address(this), 0);
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

        uint256 aTokenBalance = aToken.balanceOf(address(this));
        uint256 contractBalance = IERC20(_asset).balanceOf(address(this));

        return aTokenBalance + contractBalance;
    }

    /**
     * @notice Claims AAVE rewards and swaps them to USDC
     * @dev Internal function called during withdrawals and reporting
     */
    function _claimAndSwapRewards() internal {
        address[] memory assets = new address[](1);
        assets[0] = address(aToken);

        uint256 pendingRewards = rewardsController.getUserRewards(assets, address(this), rewardToken);

        if (pendingRewards > 0) {
            rewardsController.claimRewards(assets, pendingRewards, address(this), rewardToken);

            _swapRewardsToAsset();
        }
    }

    /**
     * @notice Swaps reward tokens to the base asset (USDC)
     * @dev Uses Uniswap V2 with a fixed path: AAVE to USDC
     */
    function _swapRewardsToAsset() internal {
        uint256 rewardBalance = IERC20(rewardToken).balanceOf(address(this));
        if (rewardBalance > 0) {
            address[] memory path = new address[](2);
            path[0] = rewardToken;
            path[1] = address(_asset);

            IUniswapV2Router(uniswapV2Router)
                .swapExactTokensForTokens(rewardBalance, 0, path, address(this), block.timestamp + swapDeadline);
        }
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
     * @param delay New deadline duration in seconds
     * @custom:role DEFAULT_ADMIN_ROLE Only callable by admin
     */
    function setSwapDeadline(uint256 delay) external onlyRole(DEFAULT_ADMIN_ROLE) {
        swapDeadline = delay;
    }
}
