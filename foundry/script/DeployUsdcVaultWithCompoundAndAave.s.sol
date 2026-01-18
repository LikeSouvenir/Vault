// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Config} from "forge-std/Config.sol";
import {console} from "forge-std/console.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVault} from "../src/interfaces/IVault.sol";
import {Vault} from "../src/Vault.sol";
import {IBaseStrategy} from "../src/interfaces/IBaseStrategy.sol";
import {CompoundUsdcStrategy} from "../src/CompoundUsdcStrategy.sol";
import {AaveUsdcStrategy} from "../src/AaveUsdcStrategy.sol";

import "forge-std/Test.sol";

uint16 constant DEFAULT_SHARE_PERCENT = 5_000;

contract DeployUsdcVaultWithCompoundAndAave is Script, Config {
    function run() external returns (Vault) {
        _loadConfig("./config.toml", true);

        address defaultManager = vm.envAddress("DEV_PUBLIC_KEY");
        address defaultFeeRecipient = vm.envAddress("RECIPIENT_PUBLIC_KEY");

        address usdc = config.get("usdc").toAddress();

        // CompoundV3
        address uniswapV2Router = config.get("uniswap_v2_router").toAddress();
        address cometUsdc = config.get("comet_usdc").toAddress();
        address cometRewards = config.get("comet_rewards").toAddress();
        address comp = config.get("comp").toAddress();

        // Aave
        //        address aavePool = config.get("aave_v3_pool").toAddress();
        //        address aToken = config.get("aave_v3_usdc_aToken").toAddress();
        //        address aaveRewardsController = config.get("aave_v3_rewards").toAddress();
        //        address aaveRewardToken = config.get("aave_reward_token").toAddress();

        vm.startBroadcast();

        // Vault
        Vault vault = new Vault(IERC20(usdc), "Vault Share Token", "VST", defaultManager, defaultFeeRecipient);

        // Compound strategy
        IBaseStrategy compoundV3 = new CompoundUsdcStrategy(
            cometUsdc, usdc, "CompoundV3", address(vault), cometRewards, comp, uniswapV2Router
        );

        // Aave strategy
        //        IBaseStrategy aaveV3 = new AaveUsdcStrategy(
        //            aavePool,
        //            usdc,
        //            "AaveV3",
        //            address(vault),
        //            aToken,
        //            aaveRewardsController,
        //            aaveRewardToken,
        //            uniswapV2Router
        //        );

        // add strategies
        vault.add(compoundV3, DEFAULT_SHARE_PERCENT);
        //        vault.add(aaveV3, DEFAULT_SHARE_PERCENT);

        // updates roles
        vault.grantRole(vault.KEEPER_ROLE(), defaultManager);

        vm.stopBroadcast();
        console.log("defaultManager", defaultManager);
        console.log("msg sender", msg.sender);

        // set addresses
        config.set("vault_usdc", address(vault));
        config.set("compound_strategy_usdc", address(compoundV3));
        //        config.set("aave_strategy_usdc", address(aaveV3));

        return vault;
    }
}
