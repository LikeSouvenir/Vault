// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBaseStrategy} from "../src/interfaces/IBaseStrategy.sol";
import {AaveUsdcStrategy} from "../src/AaveUsdcStrategy.sol";

import {Script} from "forge-std/Script.sol";
import {Config} from "forge-std/Config.sol";

contract DeployAaveUsdcStrategy is Script, Config {
    function run() external returns (IBaseStrategy) {
        _loadConfig("./config.toml", false);

        address uniswapV2Router = config.get("uniswap_v2_router").toAddress();
        address aavePool = config.get("aave_v3_pool").toAddress();
        address aToken = config.get("aave_v3_usdc_aToken").toAddress();
        address rewardsController = config.get("aave_v3_rewards_controller").toAddress();
        address usdc = config.get("usdc").toAddress();
        address rewardToken = config.get("aave_reward_token").toAddress(); // Обычно stkAAVE или другие
        address vault = config.get("vault").toAddress();

        vm.startBroadcast();
        IBaseStrategy strategy = new AaveUsdcStrategy(
            aavePool,
            usdc,
            "AaveV3",
            vault,
            aToken,
            rewardsController,
            rewardToken,
            uniswapV2Router
        );

        vm.stopBroadcast();
        return strategy;
    }
}