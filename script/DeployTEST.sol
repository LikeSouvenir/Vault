// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {TEST} from "../Vault/contracts/TEST.sol";

contract DeployTEST is Script {
    function run() external returns (TEST) {
        vm.startBroadcast();

        TEST test = new TEST();        
        // add functions

        vm.stopBroadcast();
        return test;
    }
}