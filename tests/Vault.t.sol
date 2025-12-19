// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {BaseStrategy} from "../contracts/BaseStrategy.sol";
import {Vault} from "../contracts/Vault.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import {Erc20Mock} from "./mocks/Erc20Mock.sol";
import {StackingMock} from "./mocks/StackingMock.sol";
import {StackingStrategyMock} from "./mocks/StackingStrategyMock.t.sol";

import {Test} from "forge-std/Test.sol"; 
import {stdStorage, StdStorage} from "forge-std/Test.sol"; 
import {stdError} from "forge-std/Test.sol";
import {console} from "forge-std/Test.sol";

contract VaultTest is Test {
    uint16 constant DEFAULT_FEE = 100;
    uint internal constant MAXIMUM_STRATEGIES = 20;
    bytes32 constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    string constant VAULT_NAME_SHARE_TOKEN = "vaultShare";
    string constant VAULT_SYMBOL_SHARE_TOKEN = "VS";

    Erc20Mock erc20Mock;
    StackingMock stackingMock;
    Vault vault;
    StackingStrategyMock strategyOne;
    StackingStrategyMock strategyTwo;

    address manager = vm.addr(1);
    address keeper = vm.addr(2);
    address feeRecipient= vm.addr(3);

    address user1 = vm.addr(4);
    address user2 = vm.addr(5);
    address user3 = vm.addr(6);

    function setUp() public {
        erc20Mock = new Erc20Mock();
        stackingMock = new StackingMock(erc20Mock);
        vault = new Vault(erc20Mock, VAULT_NAME_SHARE_TOKEN, VAULT_SYMBOL_SHARE_TOKEN, manager, feeRecipient);

        strategyOne = new StackingStrategyMock(erc20Mock, address(vault));
        strategyTwo = new StackingStrategyMock(erc20Mock, address(vault));

        uint DEFAULT_USER_BALANCE = 10_000 * 10 ** erc20Mock.decimals();

        erc20Mock.mint(user1, DEFAULT_USER_BALANCE);
        erc20Mock.mint(user2, DEFAULT_USER_BALANCE);
        erc20Mock.mint(user3, DEFAULT_USER_BALANCE);
    }

    function addStrategyOne() internal {
        uint16 sharePercent = 100;

        vm.startPrank(manager);
        vault.add(strategyOne, sharePercent);
    }

    function test_migrate() external {
        addStrategyOne();

        uint16 performanceFeeOldStrategy = vault.performanceFee(strategyOne);
        uint strategyBalanceOldStrategy = vault.strategyBalance(strategyOne);
        uint16 strategySharePercentOldStrategy = vault.strategySharePercent(strategyOne);

        vault.migrate(strategyOne, strategyTwo);

        uint16 performanceFeeNewStrategy = vault.performanceFee(strategyTwo);
        uint strategyBalanceNewStrategy = vault.strategyBalance(strategyTwo);
        uint16 strategySharePercentNewStrategy = vault.strategySharePercent(strategyTwo);

        BaseStrategy[MAXIMUM_STRATEGIES] memory withdrabalQueueAfter = vault.withdrabalQueue();

        vm.assertEq(address(strategyTwo), address(withdrabalQueueAfter[0]));
        vm.assertEq(performanceFeeNewStrategy, performanceFeeOldStrategy);
        vm.assertEq(strategyBalanceNewStrategy, strategyBalanceOldStrategy);
        vm.assertEq(strategySharePercentNewStrategy, strategySharePercentOldStrategy);
    }

    function test_remove() external {
        addStrategyOne();

        BaseStrategy[MAXIMUM_STRATEGIES] memory withdrabalQueueBefore = vault.withdrabalQueue();

        vm.assertEq(address(strategyOne), address(withdrabalQueueBefore[0]));
        
        vault.remove(strategyOne);

        BaseStrategy[MAXIMUM_STRATEGIES] memory withdrabalQueueAfter = vault.withdrabalQueue();
        vm.assertEq(address(0), address(withdrabalQueueAfter[0]));
    }

    function test_notExists_remove() external {
        vm.startPrank(manager);
        vm.expectRevert(bytes("strategy not exist"));
        vault.remove(strategyOne);
    }

    function test_add() external {
        uint16 sharePercent = 100;

        vm.startPrank(manager);
        vault.add(strategyOne, sharePercent);
    }

    function test_withdoutAllowance_add() external {
        uint16 sharePercent = 100;

        vm.prank(address(strategyOne));
        erc20Mock.approve(address(vault), 0);

        vm.startPrank(manager);
        vm.expectRevert(bytes("must allowance type(uint256).max"));
        vault.add(strategyOne, sharePercent);
    }

    function test_sameStrategy_add() external {
        uint16 sharePercent = 100;

        vm.startPrank(manager);
        vault.add(strategyOne, sharePercent);

        vm.expectRevert(bytes("strategy exist"));
        vault.add(strategyOne, sharePercent);
    }
 
    function test_outOfBoundsLimited_add() external {
        uint16 sharePercent = 100;

        vm.startPrank(manager);
        for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
            BaseStrategy strategy = new StackingStrategyMock(erc20Mock, address(vault));
            vault.add(strategy, sharePercent);
        }

        vm.expectRevert(bytes("limited of strategy"));
        vault.add(strategyOne, sharePercent);
    }

    function test_otherVaultIn_add() external {
        uint16 sharePercent = 100;

        Vault otherVault = new Vault(erc20Mock, "", "", manager, feeRecipient);

        BaseStrategy strategy = new StackingStrategyMock(erc20Mock, address(otherVault));

        vm.startPrank(manager);
        vm.expectRevert(bytes("bad strategy vault in"));
        vault.add(strategy, sharePercent);
    }

    function test_unsuitableToken_add() external {
        uint16 sharePercent = 100;

        Erc20Mock otherErc20 = new Erc20Mock();
        BaseStrategy strategy = new StackingStrategyMock(otherErc20, address(vault));
        
        vm.startPrank(manager);
        vm.expectRevert(bytes("bad strategy asset in"));
        vault.add(strategy, sharePercent);
    }

    function test_withoutRooles_add() external {
        uint16 sharePercent = 100;

        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, vault.DEFAULT_ADMIN_ROLE()));
        vault.add(strategyOne, sharePercent);
    }

    function test_pause() external {
        addStrategyOne();
        vault.grantRole(KEEPER_ROLE, keeper);
        vm.stopPrank();

        vm.startPrank(keeper);
        vault.pause(strategyOne);
        vm.assertTrue(strategyOne.isPaused());

        vm.expectRevert(bytes("is paused"));
        vault.pause(strategyOne);
        vm.assertTrue(strategyOne.isPaused());
    }

    function test_unpause() external {
        addStrategyOne();
        vault.grantRole(KEEPER_ROLE, keeper);
        vm.stopPrank();

        vm.startPrank(keeper);
        vault.pause(strategyOne);
        vm.assertTrue(strategyOne.isPaused());

        vault.unpause(strategyOne);
        vm.assertFalse(strategyOne.isPaused());
    }

    function test_setPerformanceFee() external {
        addStrategyOne();

        uint16 newFee = 200;
        vault.setPerformanceFee(strategyOne, newFee);

        uint16 currentFee = vault.performanceFee(strategyOne);
        vm.assertEq(newFee, currentFee);
    }

    function test_more100PersentFee_setPerformanceFee() external {
        addStrategyOne();

        uint16 newFee = 10_001;
        vm.expectRevert(bytes("max % is 100"));
        vault.setPerformanceFee(strategyOne, newFee);
    }

    function test_zerpFee_setPerformanceFee() external {
        addStrategyOne();

        uint16 newFee = 0;
        vm.expectRevert(bytes("min % is 0,01"));
        vault.setPerformanceFee(strategyOne, newFee);
    }

    function test_setManagementFee() external {
        addStrategyOne();

        uint16 newFee = 200;
        vault.setManagementFee(newFee);

        uint16 currentFee = vault.managementFee();
        vm.assertEq(newFee, currentFee);
    }

    function test_more100PersentFee_setManagementFee() external {
        addStrategyOne();

        uint16 newFee = 10_001;
        vm.expectRevert(bytes("max % is 100"));
        vault.setManagementFee(newFee);
    }

    function test_zeroFee_setManagementFee() external {
        addStrategyOne();

        uint16 newFee = 0;
        vm.expectRevert(bytes("min % is 0,01"));
        vault.setManagementFee(newFee);
    }
    
    function test_setFeeRecipient() external {
        addStrategyOne();
        address newFeeRecipient = vm.addr(100);
        vault.setFeeRecipient(newFeeRecipient);

        address currentRecipient = vault.feeRecipient();
        vm.assertEq(newFeeRecipient, currentRecipient);
    }

    function test_zeroAddress_setFeeRecipient() external {
        addStrategyOne();
        vm.expectRevert(bytes("zero address"));
        vault.setFeeRecipient(address(0));
    }

    function test_performanceFee() external {
        addStrategyOne();
        
        uint16 fee = vault.performanceFee(strategyOne);
        vm.assertEq(fee, DEFAULT_FEE);
    }

    function test_setWithdrawalQueue() external {
        uint16 sharePercent = 100;

        vm.startPrank(manager);
        vault.add(strategyOne, sharePercent);
        vault.add(strategyTwo, sharePercent);

        BaseStrategy[MAXIMUM_STRATEGIES] memory oldWithdrabalQueue = vault.withdrabalQueue();

        BaseStrategy[MAXIMUM_STRATEGIES] memory newWithdrabalQueue;
        newWithdrabalQueue[0] = strategyTwo;
        newWithdrabalQueue[1] = strategyOne;

        vault.setWithdrawalQueue(newWithdrabalQueue);

        newWithdrabalQueue = vault.withdrabalQueue();
        
        vm.assertEq(address(newWithdrabalQueue[0]), address(oldWithdrabalQueue[1]));
        vm.assertEq(address(newWithdrabalQueue[1]), address(oldWithdrabalQueue[0]));
    }

    function test_withChangeStrategy_setWithdrawalQueue() external {
        uint16 sharePercent = 100;

        vm.startPrank(manager);
        vault.add(strategyOne, sharePercent);
        vault.add(strategyTwo, sharePercent);

        BaseStrategy[MAXIMUM_STRATEGIES] memory newWithdrabalQueue;
        newWithdrabalQueue[0] = new StackingStrategyMock(erc20Mock, address(vault));
        newWithdrabalQueue[1] = strategyOne;

        vm.expectRevert(bytes("Cannot use to change strategies"));
        vault.setWithdrawalQueue(newWithdrabalQueue);
    }

    function test_withdrabalQueue() external {
        addStrategyOne();

        BaseStrategy[MAXIMUM_STRATEGIES] memory withdrabalQueue = vault.withdrabalQueue();
        vm.assertEq(address(strategyOne), address(withdrabalQueue[0]));
    }

    function test_managementFee() external view {
        uint16 fee = vault.managementFee();
        vm.assertEq(fee, DEFAULT_FEE);
    }

    function test_feeRecipient() external view {
        address recipient = vault.feeRecipient();
        vm.assertEq(recipient, feeRecipient);
    }
}