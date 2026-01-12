// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Script} from "forge-std/Script.sol";
import {Config} from "forge-std/Config.sol";
import {console} from "forge-std/console.sol";

import {Vault} from "../src/Vault.sol";
import {IBaseStrategy} from "../src/interfaces/IBaseStrategy.sol";
import {CompoundUsdcStrategy} from "../src/CompoundUsdcStrategy.sol";

uint constant DEFAULT_SHARE_PERCENT = 5_000;

contract DeployUsdcVaultWithCompoundAndAave is Script, Config {
    function run() external returns (Vault) {
        _loadConfig("./config.toml", true);

        address defaultManager = vm.envAddress("DEV_PUBLIC_KEY");
        address defaultFeeRecipient =  vm.envAddress("RECIPIENT_PUBLIC_KEY");

        address uniswapV2Router = config.get("uniswap_v2_router").toAddress();
        address cometUsdc = config.get("comet_usdc").toAddress();
        address cometRewards = config.get("comet_rewards").toAddress();
        address usdc = config.get("usdc").toAddress();
        address comp = config.get("comp").toAddress();
        address vault = config.get("vault").toAddress();

        address token = ERC4626(vault).asset();
        require(token == usdc, "incorrect asset token");

        vm.startBroadcast();

        IVault vault = new Vault(
            IERC20(usdc),
            "Vault Share Token",
            "VST",
            defaultManager,
            defaultFeeRecipient
        );

        IBaseStrategy compoundV3 = new CompoundUsdcStrategy(
            cometUsdc,
            usdc,
            "CompoundV3",
            vault,
            cometRewards,
            comp,
            uniswapV2Router
        );
        // Aave strategy

        // add functions
        vault.add(compoundV3, DEFAULT_SHARE_PERCENT);

        vault.grantRole(0x00, defaultManager);
        vault.revokeRole(0x00, msg.sender);

        vm.stopBroadcast();

        config.set("vault", address(vault));

        return vault;
    }
}
