// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Script} from "forge-std/Script.sol";
import {Config} from "forge-std/Config.sol";
import {console} from "forge-std/console.sol";

import {Vault} from "../src/Vault.sol";
import {BaseStrategy} from "../src/BaseStrategy.sol";

contract DeployVault is Script, Config {
    function run() external returns (Vault) {
        _loadConfig("./config.toml", true);

        address WETH = config.get("weth").toAddress();
        address DEFAULT_MANAGER = 0x1C969b20A5985c02721FCa20c44F9bf8931856a8;
        address DEFAULT_FEE_RECIPIENT = 0x8A969F0C98ff14c5fa92d75aadE3f329141a3384;

        string memory VAULT_NAME = "Vault Share Token";
        string memory VAULT_SYMBOL = "VST";

        vm.startBroadcast();

        Vault vault = new Vault(IERC20(WETH), VAULT_NAME, VAULT_SYMBOL, DEFAULT_MANAGER, DEFAULT_FEE_RECIPIENT);

        // add functions

        vm.stopBroadcast();

        config.set("vault", address(vault));

        return vault;
    }
}
