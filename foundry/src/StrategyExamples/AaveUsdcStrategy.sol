// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {BaseStrategy} from "../BaseStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV2Router} from "../interfaces/IUniswapV2Router.sol";
import {IPool, IRewardsController, IAToken} from "../interfaces/IAaveV3.sol";

contract AaveUsdcStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    IPool public immutable aavePool;
    IAToken public immutable aToken;
    IRewardsController public immutable rewardsController;
    address public immutable rewardToken;
    address public immutable uniswapV2Router;
    uint256 public swapDeadline = 1 hours;

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

    function _push(uint256 _amount) internal virtual override {
        require(_asset.approve(address(aToken), _amount), "approve failed");
        aavePool.supply(address(_asset), _amount, address(this), 0);
    }

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

    function _claimAndSwapRewards() internal {
        // Подготавливаем массив активов для клейма наград
        address[] memory assets = new address[](1);
        assets[0] = address(aToken);

        // Проверяем доступные награды
        uint256 pendingRewards = rewardsController.getUserRewards(assets, address(this), rewardToken);

        if (pendingRewards > 0) {
            // Клеймим награды
            rewardsController.claimRewards(assets, pendingRewards, address(this), rewardToken);

            // Конвертируем награды в базовый актив
            _swapRewardsToAsset();
        }
    }

    function _swapRewardsToAsset() internal {
        uint256 rewardBalance = IERC20(rewardToken).balanceOf(address(this));
        if (rewardBalance > 0) {
            address[] memory path = new address[](2);
            path[0] = rewardToken;
            path[1] = address(_asset);

            // Используем UniswapV2 интерфейс (аналогично Compound стратегии)
            IUniswapV2Router(uniswapV2Router)
                .swapExactTokensForTokens(rewardBalance, 0, path, address(this), block.timestamp + swapDeadline);
        }
    }

    function harvest() external onlyRole(KEEPER_ROLE) {
        _claimAndSwapRewards();
    }

    function setSwapDeadline(uint256 delay) external onlyRole(DEFAULT_ADMIN_ROLE) {
        swapDeadline = delay;
    }
}
