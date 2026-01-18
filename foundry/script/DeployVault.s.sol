// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVault} from "../src/interfaces/IVault.sol";
import {Vault} from "../src/Vault.sol";

import {Script} from "forge-std/Script.sol";
import {Config} from "forge-std/Config.sol";

contract DeployVault is Script, Config {
    function run() external returns (IVault) {
        _loadConfig("./config.toml", true);

        address weth = config.get("weth").toAddress();
        address defaultManager = vm.envAddress("DEV_PUBLIC_KEY");
        address defaultFeeRecipient = vm.envAddress("RECIPIENT_PUBLIC_KEY");

        vm.startBroadcast();

        IVault vault = new Vault(IERC20(weth), "Vault Share Token", "VST", defaultManager, defaultFeeRecipient);

        vm.stopBroadcast();

        config.set("vault", address(vault));

        return vault;
    }
}
