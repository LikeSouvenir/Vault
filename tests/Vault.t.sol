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
    uint constant BPS = 10_000;
    uint16 constant DEFAULT_FEE = 100;
    uint16 constant MAX_PERSENT = 10_000;
    uint16 constant MIN_PERSENT = 1;
    uint constant MAXIMUM_STRATEGIES = 20;
    bytes32 constant KEEPER_ROLE = keccak256("KEEPER_ROLE");


    uint constant DEFAULT_USER_BALANCE = 10_000e18;
    uint16 constant TEST_INVEST_VALUE = 10_000;
    uint16 constant TEST_STRATEGY_SHARE_PERSENT = 1_000;
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
        vm.warp(1766389559);

        erc20Mock = new Erc20Mock();
        stackingMock = new StackingMock(erc20Mock);
        vault = new Vault(erc20Mock, VAULT_NAME_SHARE_TOKEN, VAULT_SYMBOL_SHARE_TOKEN, manager, feeRecipient);

        strategyOne = new StackingStrategyMock(stackingMock, erc20Mock, address(vault));
        strategyTwo = new StackingStrategyMock(stackingMock, erc20Mock, address(vault));

        erc20Mock.mint(user1, DEFAULT_USER_BALANCE);
        erc20Mock.mint(user2, DEFAULT_USER_BALANCE);
        erc20Mock.mint(user3, DEFAULT_USER_BALANCE);
        
        vm.prank(manager);
        vault.grantRole(KEEPER_ROLE, keeper);
    }

    event UpdateManagementRecipient(address indexed recipient);
    
    event UpdateManagementFee(uint16 indexed fee);

    event UpdatePerformanceFee(address indexed strategy, uint16 indexed newFee);
    
    event UpdateStrategySharePercent(address indexed strategy, uint newPercent);

    event StrategyAdded (address indexed strategy);

    event UpdateStrategyBalance(BaseStrategy indexed strategy, uint newBalance);
    
    event UpdateWithdrawalQueue(BaseStrategy[MAXIMUM_STRATEGIES]);

    event StrategyMigrated (address indexed oldVersion, address indexed newVersion );

    event StrategyRemoved (address indexed strategy, uint totalAssets);
    
    event EmergencyWithdraw(uint timestamp, uint amount);

    event Reported(
        uint256 profit,
        uint256 loss,
        uint256 managementFees,
        uint256 performanceFees
    );

    function _setUpWithStrategyOne() internal {
        vm.startPrank(manager);
        vault.add(strategyOne, TEST_STRATEGY_SHARE_PERSENT);
    }

    function _setUpWithStrategyOneAndTwoWithMaxSharePersent() internal {
        vm.startPrank(manager);
        vault.add(strategyOne, MAX_PERSENT / 2);
        vault.add(strategyTwo, MAX_PERSENT / 2);
        vm.stopPrank();
    }

    function _setUpWithLiquidityStrategyOne() internal {
        _setUpWithStrategyOne();
        vault.setSharePercent(strategyOne, MAX_PERSENT);
        vm.stopPrank();

        _depositFrom(user2);

        vm.prank(address(keeper));
        vault.rebalance(strategyOne);
    } 

    function _depositFrom(address user) internal {
        vm.startPrank(user);
        erc20Mock.approve(address(vault), TEST_INVEST_VALUE);
        vault.deposit(TEST_INVEST_VALUE, user);
        vm.stopPrank();
    }

    function test_notEnaugthVaultToken_withdraw() external {
        _setUpWithStrategyOneAndTwoWithMaxSharePersent();

        _depositFrom(user2);
        _depositFrom(user3);

        vm.prank(address(keeper));
        vault.reportsAndInvests();

        uint vaultBalance = erc20Mock.balanceOf(address(vault));
        vm.assertEq(vaultBalance, 0);

        uint user2Balance = erc20Mock.balanceOf(user2);

        vm.startPrank(user2);
        vault.withdraw(TEST_INVEST_VALUE, user2, user2);

        vm.assertEq(user2Balance + TEST_INVEST_VALUE, DEFAULT_USER_BALANCE);
    }

    function test_reportsAndInvests() external {
        _setUpWithStrategyOneAndTwoWithMaxSharePersent();

        _depositFrom(user2);

        uint balanceStrategyOne = vault.strategyBalance(strategyOne);
        uint balanceStrategyTwo = vault.strategyBalance(strategyTwo);

        vm.assertEq(balanceStrategyOne, 0);
        vm.assertEq(balanceStrategyTwo, 0);

        vm.startPrank(keeper);
        vault.reportsAndInvests();

        balanceStrategyOne = vault.strategyBalance(strategyOne);
        balanceStrategyTwo = vault.strategyBalance(strategyTwo);

        vm.assertEq(balanceStrategyOne, TEST_INVEST_VALUE / 2);
        vm.assertEq(balanceStrategyTwo, TEST_INVEST_VALUE / 2);
    }

    function test_withManagmentFee_report() external {
        _setUpWithLiquidityStrategyOne();

        uint expectedProfit = stackingMock.calculateProfit(TEST_INVEST_VALUE);
        uint strategyBalance = vault.strategyBalance(strategyOne);
        uint performanceFee = vault.strategyPerformanceFee(strategyOne);
        uint managementFee = vault.managementFee();
        
        uint expectedPerformanceFee = expectedProfit * performanceFee / BPS;
        uint expectedManagementFee = strategyBalance * managementFee / BPS / 12;

        vm.expectEmit(true, true, true, true);
        emit Reported(expectedProfit, 0, expectedManagementFee, expectedPerformanceFee);

        vm.warp(block.timestamp + 32 days);
        vm.startPrank(keeper);
        vault.report(strategyOne);  
        
        uint recipientBalance = vault.balanceOf(feeRecipient);
        vm.assertEq(recipientBalance, expectedPerformanceFee + expectedManagementFee);
    }

    function test_withLoss_report() external {
        _setUpWithLiquidityStrategyOne();
        stackingMock.setIsReturnedProfit(false);

        uint expectedLoss = stackingMock.calculateLoss(TEST_INVEST_VALUE);
        uint expectedPerformanceFee = 0;

        vm.expectEmit(true, true, true, true);
        emit Reported(0, expectedLoss, 0, expectedPerformanceFee);

        vm.startPrank(keeper);
        vault.report(strategyOne);

        uint recipientBalance = vault.balanceOf(feeRecipient);
        vm.assertEq(recipientBalance, expectedPerformanceFee);
    }

    function test_withProfit_report() external {
        _setUpWithLiquidityStrategyOne();

        uint expectedProfit = stackingMock.calculateProfit(TEST_INVEST_VALUE);
        uint performanceFee = vault.strategyPerformanceFee(strategyOne);

        uint expectedPerformanceFee = (expectedProfit * performanceFee) / BPS;

        vm.expectEmit(true, true, true, true);
        emit Reported(expectedProfit, 0, 0, expectedPerformanceFee);

        vm.startPrank(keeper);
        vault.report(strategyOne);

        uint recipientBalance = vault.balanceOf(feeRecipient);
        vm.assertEq(recipientBalance, expectedPerformanceFee);
    }


    function test_whenNotPaused_emergencyWithdraw() external {
        _setUpWithLiquidityStrategyOne();

        uint profit = stackingMock.calculateProfit(TEST_INVEST_VALUE);

        uint balanceVaultBefore = erc20Mock.balanceOf(address(vault));
        uint balanceStackingBefore = stackingMock.getBalance(address(strategyOne));
        vm.assertEq(balanceVaultBefore, 0);
        vm.assertEq(balanceStackingBefore, TEST_INVEST_VALUE);

        vm.assertFalse(strategyOne.isPaused());

        vm.startPrank(manager);
        vault.emergencyWithdraw(strategyOne);

        uint balanceVaultAfterEmergency = erc20Mock.balanceOf(address(vault));
        uint balanceStackingAfter = stackingMock.getBalance(address(strategyOne));

        vm.assertEq(balanceStackingAfter, 0);
        vm.assertEq(balanceVaultAfterEmergency, TEST_INVEST_VALUE + profit);
    }

    function test_whenPaused_emergencyWithdraw() external {
        _setUpWithLiquidityStrategyOne();

        uint profit = stackingMock.calculateProfit(TEST_INVEST_VALUE);

        vm.startPrank(address(keeper));

        uint balanceStrategyBefore = erc20Mock.balanceOf(address(strategyOne));
        uint balanceVaultBefore = erc20Mock.balanceOf(address(vault));
        vm.assertEq(balanceVaultBefore, 0);
        vm.assertEq(balanceStrategyBefore, 0);

        vault.pause(strategyOne);
        vm.stopPrank();

        uint balanceStrategyAfter = erc20Mock.balanceOf(address(strategyOne));
        uint balanceVaultAfter = erc20Mock.balanceOf(address(vault));

        vm.assertTrue(strategyOne.isPaused());
        vm.assertEq(balanceStrategyAfter, TEST_INVEST_VALUE + profit);
        vm.assertEq(balanceVaultAfter, 0);

        vm.startPrank(manager);
        vault.emergencyWithdraw(strategyOne);

        uint balanceStrategyAfterEmergency = erc20Mock.balanceOf(address(strategyOne));
        uint balanceVaultAfterEmergency = erc20Mock.balanceOf(address(vault));

        vm.assertEq(balanceStrategyAfterEmergency, 0);
        vm.assertEq(balanceVaultAfterEmergency, TEST_INVEST_VALUE + profit);
    }

    function strategySharePercent() external {
        _setUpWithLiquidityStrategyOne();

        uint16 sharePersent = vault.strategySharePercent(strategyOne);

        vm.assertEq(sharePersent, TEST_STRATEGY_SHARE_PERSENT);
    }

    function test_strategyBalance() external {
        _setUpWithLiquidityStrategyOne();

        uint balance = vault.strategyBalance(strategyOne);

        vm.assertEq(balance, TEST_INVEST_VALUE);
    }

    function test_setSharePercent() external {
        _setUpWithStrategyOne();

        vault.setSharePercent(strategyOne, MAX_PERSENT); 

        uint16 sharePersent = vault.strategySharePercent(strategyOne);

        vm.assertEq(sharePersent, MAX_PERSENT);
    }

    function test_strategySharePercent() external {
        _setUpWithStrategyOne();

        uint16 sharePersent = vault.strategySharePercent(strategyOne);

        vm.assertEq(sharePersent, TEST_STRATEGY_SHARE_PERSENT);
    }

    function test_rebalance() external {
        // first
        _setUpWithLiquidityStrategyOne();

        uint strategyOneLastTotalAsset = strategyOne.lastTotalAssets();
        vm.assertEq(strategyOneLastTotalAsset, TEST_INVEST_VALUE);

        // second
        _depositFrom(user1);

        vm.prank(address(keeper));
        vault.rebalance(strategyOne);

        uint strategyOneTotalAsset = stackingMock.getBalance(address(strategyOne));
        vm.assertEq(strategyOneTotalAsset, TEST_INVEST_VALUE * 2);
    }

    function test_migrate() external {
        _setUpWithStrategyOne();

        uint16 performanceFeeOldStrategy = vault.strategyPerformanceFee(strategyOne);
        uint strategyBalanceOldStrategy = vault.strategyBalance(strategyOne);
        uint16 strategySharePercentOldStrategy = vault.strategySharePercent(strategyOne);

        vault.migrate(strategyOne, strategyTwo);

        uint16 performanceFeeNewStrategy = vault.strategyPerformanceFee(strategyTwo);
        uint strategyBalanceNewStrategy = vault.strategyBalance(strategyTwo);
        uint16 strategySharePercentNewStrategy = vault.strategySharePercent(strategyTwo);

        BaseStrategy[MAXIMUM_STRATEGIES] memory withdrabalQueueAfter = vault.withdrabalQueue();

        vm.assertEq(address(strategyTwo), address(withdrabalQueueAfter[0]));
        vm.assertEq(performanceFeeNewStrategy, performanceFeeOldStrategy);
        vm.assertEq(strategyBalanceNewStrategy, strategyBalanceOldStrategy);
        vm.assertEq(strategySharePercentNewStrategy, strategySharePercentOldStrategy);
    }

    function test_remove() external {
        _setUpWithStrategyOne();

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
        vm.startPrank(manager);
        vault.add(strategyOne, TEST_STRATEGY_SHARE_PERSENT);
    }

    function test_withdoutAllowance_add() external {
        vm.prank(address(strategyOne));
        erc20Mock.approve(address(vault), 0);

        vm.startPrank(manager);
        vm.expectRevert(bytes("must allowance type(uint256).max"));
        vault.add(strategyOne, TEST_STRATEGY_SHARE_PERSENT);
    }

    function test_sameStrategy_add() external {
        vm.startPrank(manager);
        vault.add(strategyOne, TEST_STRATEGY_SHARE_PERSENT);

        vm.expectRevert(bytes("strategy exist"));
        vault.add(strategyOne, TEST_STRATEGY_SHARE_PERSENT);
    }
 
    function test_outOfBoundsLimited_add() external {
        vm.startPrank(manager);
        for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
            BaseStrategy strategy = new StackingStrategyMock(stackingMock, erc20Mock, address(vault));
            vault.add(strategy, TEST_STRATEGY_SHARE_PERSENT / uint16(MAXIMUM_STRATEGIES));
        }

        vm.expectRevert(bytes("limited of strategy"));
        vault.add(strategyOne, TEST_STRATEGY_SHARE_PERSENT);
    }

    function test_otherVaultIn_add() external {
        Vault otherVault = new Vault(erc20Mock, "", "", manager, feeRecipient);

        BaseStrategy strategy = new StackingStrategyMock(stackingMock, erc20Mock, address(otherVault));

        vm.startPrank(manager);
        vm.expectRevert(bytes("bad strategy vault in"));
        vault.add(strategy, TEST_STRATEGY_SHARE_PERSENT);
    }

    function test_unsuitableToken_add() external {
        Erc20Mock otherErc20 = new Erc20Mock();
        BaseStrategy strategy = new StackingStrategyMock(stackingMock, otherErc20, address(vault));
        
        vm.startPrank(manager);
        vm.expectRevert(bytes("bad strategy asset in"));
        vault.add(strategy, TEST_STRATEGY_SHARE_PERSENT);
    }

    function test_withoutRooles_add() external {
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, vault.DEFAULT_ADMIN_ROLE()));
        vault.add(strategyOne, TEST_STRATEGY_SHARE_PERSENT);
    }

    function test_totalAssets() external {
        uint totalAssets = vault.totalAssets();

        vm.assertEq(totalAssets, 0);
        _setUpWithStrategyOne();
        vm.stopPrank();

        _depositFrom(user1);

        vm.startPrank(user1);
        totalAssets = vault.maxWithdraw(user1);
        vm.assertEq(totalAssets, TEST_INVEST_VALUE);
    }

    function test_maxWithdraw() external {
        uint max = vault.maxWithdraw(user1);

        vm.assertEq(max, 0);
        _setUpWithStrategyOne();
        vm.stopPrank();

        _depositFrom(user1);

        vm.startPrank(user1);
        max = vault.maxWithdraw(user1);
        vm.assertEq(max, TEST_INVEST_VALUE);
    }

    function test_maxRedeem() external {
        uint max = vault.maxRedeem(user1);

        vm.assertEq(max, 0);
        _setUpWithStrategyOne();
        vm.stopPrank();

        _depositFrom(user1);

        vm.startPrank(user1);
        max = vault.maxRedeem(user1);
        vm.assertEq(max, TEST_INVEST_VALUE);
    }

    function test_pause() external {
        _setUpWithStrategyOne();
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
        _setUpWithStrategyOne();
        vault.grantRole(KEEPER_ROLE, keeper);
        vm.stopPrank();

        vm.startPrank(keeper);
        vault.pause(strategyOne);
        vm.assertTrue(strategyOne.isPaused());

        vault.unpause(strategyOne);
        vm.assertFalse(strategyOne.isPaused());
    }

    function test_setPerformanceFee() external {
        _setUpWithStrategyOne();

        uint16 newFee = 200;
        vault.setPerformanceFee(strategyOne, newFee);

        uint16 currentFee = vault.strategyPerformanceFee(strategyOne);
        vm.assertEq(newFee, currentFee);
    }

    function test_more100PersentFee_setPerformanceFee() external {
        _setUpWithStrategyOne();

        uint16 newFee = 10_001;
        vm.expectRevert(bytes("max % is 100"));
        vault.setPerformanceFee(strategyOne, newFee);
    }

    function test_zerpFee_setPerformanceFee() external {
        _setUpWithStrategyOne();

        uint16 newFee = 0;
        vm.expectRevert(bytes("min % is 0,01"));
        vault.setPerformanceFee(strategyOne, newFee);
    }

    function test_setManagementFee() external {
        _setUpWithStrategyOne();

        uint16 newFee = 200;
        vault.setManagementFee(newFee);

        uint16 currentFee = vault.managementFee();
        vm.assertEq(newFee, currentFee);
    }

    function test_more100PersentFee_setManagementFee() external {
        _setUpWithStrategyOne();

        uint16 newFee = 10_001;
        vm.expectRevert(bytes("max % is 100"));
        vault.setManagementFee(newFee);
    }

    function test_zeroFee_setManagementFee() external {
        _setUpWithStrategyOne();

        uint16 newFee = 0;
        vm.expectRevert(bytes("min % is 0,01"));
        vault.setManagementFee(newFee);
    }
    
    function test_setFeeRecipient() external {
        _setUpWithStrategyOne();
        address newFeeRecipient = vm.addr(100);
        vault.setFeeRecipient(newFeeRecipient);

        address currentRecipient = vault.feeRecipient();
        vm.assertEq(newFeeRecipient, currentRecipient);
    }

    function test_zeroAddress_setFeeRecipient() external {
        _setUpWithStrategyOne();
        vm.expectRevert(bytes("zero address"));
        vault.setFeeRecipient(address(0));
    }

    function test_performanceFee() external {
        _setUpWithStrategyOne();
        
        uint16 fee = vault.strategyPerformanceFee(strategyOne);
        vm.assertEq(fee, DEFAULT_FEE);
    }

    function test_setWithdrawalQueue() external {
        vm.startPrank(manager);
        vault.add(strategyOne, TEST_STRATEGY_SHARE_PERSENT);
        vault.add(strategyTwo, TEST_STRATEGY_SHARE_PERSENT);

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
        vm.startPrank(manager);
        vault.add(strategyOne, TEST_STRATEGY_SHARE_PERSENT);
        vault.add(strategyTwo, TEST_STRATEGY_SHARE_PERSENT);

        BaseStrategy[MAXIMUM_STRATEGIES] memory newWithdrabalQueue;
        newWithdrabalQueue[0] = new StackingStrategyMock(stackingMock, erc20Mock, address(vault));
        newWithdrabalQueue[1] = strategyOne;

        vm.expectRevert(bytes("Cannot use to change strategies"));
        vault.setWithdrawalQueue(newWithdrabalQueue);
    }

    function test_withdrabalQueue() external {
        _setUpWithStrategyOne();

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