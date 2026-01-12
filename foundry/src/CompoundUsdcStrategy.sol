// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {BaseStrategy} from "./BaseStrategy.sol";
import {IComet, ICometRewards} from "./interfaces/IComet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract CompoundUsdcStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    IComet private comet;
    ICometRewards public cometRewards;
    address public immutable COMP;
    address public immutable UNISWAP_ROUTER;

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
        cometRewards = ICometRewards(cometRewards_);
        COMP = rewardToken_;
        UNISWAP_ROUTER = uniswapRouter_;

        address token = comet.baseToken();
        require(token == token_, "invalid token");

        IERC20(token_).forceApprove(comet_, type(uint256).max);
        IERC20(rewardToken_).forceApprove(uniswapRouter_, type(uint256).max);
    }

    function _pull(uint256 _amount) internal virtual override returns (uint256) {
        uint256 balanceBefore = IERC20(_asset).balanceOf(address(this));
        uint256 balance = comet.balanceOf(address(this));

        if (_amount > balanceBefore) {
            _claimRewards();
            _swapRewardsToAsset();
        }

        comet.withdraw(address(_asset), _amount);
        uint256 balanceAfter = IERC20(_asset).balanceOf(address(this));

        return balanceAfter - balanceBefore;
    }

    function _push(uint256 _amount) internal virtual override {
        _asset.approve(address(comet), _amount);
        comet.supply(address(_asset), _amount);
    }

    function _harvestAndReport() internal virtual override returns (uint256 _totalAssets) {
        _claimRewards();
        _swapRewardsToAsset();

        uint256 assetBalance = IERC20(_asset).balanceOf(address(this));
        if (assetBalance > 0) {
            _push(assetBalance);
        }

        return comet.balanceOf(address(this));
    }

    function _claimRewards() internal {
        // В Compound v3 награды через отдельный контракт
        // Для примера предположим, исполльзуем метод claim
        try cometRewards.claim(address(comet), address(this), true) {} catch {}
    }

    function _swapRewardsToAsset() internal {
        uint256 rewardBalance = IERC20(COMP).balanceOf(address(this));
        if (rewardBalance == 0) return;

        address[] memory path = new address[](2);
        path[0] = COMP;
        path[1] = address(_asset);

        IUniswapV2Router(UNISWAP_ROUTER)
            .swapExactTokensForTokens(
                rewardBalance,
                0, // любой курс
                path,
                address(this),
                block.timestamp + 1 hours
            );
    }

    function harvest() external onlyRole(KEEPER_ROLE) {
        _claimRewards();
        _swapRewardsToAsset();
    }
}
