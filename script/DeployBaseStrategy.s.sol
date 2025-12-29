// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {Script} from "forge-std/Script.sol";
import {BaseStrategy} from "../Vault/contracts/BaseStrategy.sol";
import {BaseStrategyWrapper} from "../Vault/tests/wrappers/BaseStrategyWrapper.sol";

contract DeployBaseStrategy is Script {
    function run() external returns (BaseStrategy) {
        vm.startBroadcast();
        
        // Деплоим контракт
        address USDC = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;
        address VAULT = address(0);//????????????????????????????

        string memory NAME_BASE_STRATEGY = "AAVE";

        BaseStrategy strategy = BaseStrategy(new BaseStrategyWrapper(address(0), IERC20(USDC), NAME_BASE_STRATEGY, VAULT));
        
        vm.stopBroadcast();
        return strategy;
    }
}