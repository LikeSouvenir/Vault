// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

import {Script} from "forge-std/Script.sol";
import {Config} from "forge-std/Config.sol";

import {BaseStrategy} from "../src/BaseStrategy.sol";
import {CompoundUSDCStrategy} from "../src/CompoundUSDCStrategy.sol";

contract DeployCompoundStrategy is Script, Config {
    function run() external returns (BaseStrategy) {
        //        _loadConfig("./config.toml", false);
        //
        //        address COMET_USDC = config.get("comet_usdc").toAddress();
        //        address USDC = config.get("usdc").toAddress();
        //        address COMP = config.get("comp").toAddress();
        //        address WETH = config.get("weth").toAddress();
        //        address VAULT = config.get("vault").toAddress();
        //
        //        address token = ERC4626(VAULT).asset();
        //
        //        require(token == WETH, "bad asset token");
        //
        //        vm.startBroadcast();
        //        BaseStrategy strategy = new CompoundUSDCStrategy(COMET_USDC, USDC, "CompoundV3", VAULT);
        //
        //        vm.stopBroadcast();
        //        return strategy;
    }
}
