// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;


import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {BaseStrategy} from "../contracts/BaseStrategy.sol";
import {Vault} from "../contracts/Vault.sol";

import {Erc20Mock} from "./mocks/Erc20Mock.sol";
import {StackingMock} from "./mocks/StackingMock.sol";
import {StackingStrategyMock} from "./mocks/StackingStrategyMock.t.sol";

import {Test} from "forge-std/Test.sol"; 
import {stdStorage, StdStorage} from "forge-std/Test.sol"; 
import {stdError} from "forge-std/Test.sol";
import {console} from "forge-std/Test.sol";

contract VaultTest is Test {
    string constant VAULT_NAME_SHARE_TOKEN = "vaultShare";
    string constant VAULT_SYMBOL_SHARE_TOKEN = "VS";

    Erc20Mock erc20Mock;
    StackingMock stackingMock;
    Vault vault;
    StackingStrategyMock stackingStrategyMock;

    address vaultManager = vm.addr(1);
    address vaultFeeRecipient= vm.addr(2);

    address user1 = vm.addr(1);
    address user2 = vm.addr(2);
    address user3 = vm.addr(3);

    function setUp() public {
        erc20Mock = new Erc20Mock();
        stackingMock = new StackingMock(erc20Mock);
        vault = new Vault(erc20Mock, VAULT_NAME_SHARE_TOKEN, VAULT_SYMBOL_SHARE_TOKEN, vaultManager, vaultFeeRecipient);

        stackingStrategyMock = new StackingStrategyMock(erc20Mock, address(vault));

        uint DEFAULT_USER_BALANCE = 10_000 * 10 ** erc20Mock.decimals();

        erc20Mock.mint(user1, DEFAULT_USER_BALANCE);
        erc20Mock.mint(user2, DEFAULT_USER_BALANCE);
        erc20Mock.mint(user3, DEFAULT_USER_BALANCE);
    }

}