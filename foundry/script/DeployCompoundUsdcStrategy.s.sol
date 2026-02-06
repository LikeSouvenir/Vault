// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

//import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IBaseStrategy} from "../src/interfaces/IBaseStrategy.sol";
import {CompoundUsdcStrategy} from "../src/StrategyExamples/CompoundUsdcStrategy.sol";

import {Script} from "forge-std/Script.sol";
import {Config} from "forge-std/Config.sol";

contract DeployCompoundUsdcStrategy is Script, Config {
    function run() external returns (IBaseStrategy) {
        _loadConfig("./config.toml", false);

        address uniswapV2Router = config.get("uniswap_v2_router").toAddress();
        address cometUsdc = config.get("comet_usdc").toAddress();
        address cometRewards = config.get("comet_rewards").toAddress();
        address usdc = config.get("usdc").toAddress();
        address comp = config.get("comp").toAddress();
        address compUsd = config.get("comp_usd").toAddress();
        address vault = config.get("vault").toAddress();

        address token = ERC4626(vault).asset();
        require(token == usdc, "incorrect asset token");

        vm.startBroadcast();
        IBaseStrategy strategy =
            new CompoundUsdcStrategy(cometUsdc, usdc, "CompoundV3", vault, cometRewards, comp, uniswapV2Router, compUsd);

        vm.stopBroadcast();
        return strategy;
    }
}
