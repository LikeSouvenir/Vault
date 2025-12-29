// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {Script} from "forge-std/Script.sol";
import {Vault} from "../Vault/contracts/Vault.sol";
import {BaseStrategy} from "../Vault/contracts/BaseStrategy.sol";

contract DeployVault is Script {
    function run() external returns (Vault) {
        vm.startBroadcast();

        address USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238; 
        address DEFAULT_FEE_RECIPIENT = 0x8A969F0C98ff14c5fa92d75aadE3f329141a3384;
        address DEFAULT_MANAGER = 0x1C969b20A5985c02721FCa20c44F9bf8931856a8;
        string memory VAULT_NAME = "Vault Share Token";
        string memory VAULT_SYMBOL = "VST";
        
        Vault vault = new Vault(IERC20(USDC), VAULT_NAME, VAULT_SYMBOL, DEFAULT_MANAGER, DEFAULT_FEE_RECIPIENT);
        
        // add functions

        vm.stopBroadcast();
        return vault;
    }
}