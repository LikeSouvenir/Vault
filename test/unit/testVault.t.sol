// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {IBaseStrategy} from "../../src/interfaces/IBaseStrategy.sol";
import {Vault} from "../../src/Vault.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import {Erc20Mock} from "../mocks/Erc20Mock.sol";
import {StackingMock} from "../mocks/StackingMock.sol";
import {BaseStrategyWrapper} from "../wrappers/BaseStrategyWrapper.sol";

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/Test.sol";

uint256 constant BPS = 10_000;
uint16 constant DEFAULT_FEE = 100;
uint16 constant MAX_PERCENT = 10_000;
uint16 constant MIN_PERCENT = 1;
uint256 constant MAXIMUM_STRATEGIES = 20;
bytes32 constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

uint256 constant SECONDS_PER_YEAR = 31_556_952; // 365.2425 days
uint256 constant DEFAULT_USER_BALANCE = 10_000e18;
uint256 constant TEST_INVEST_VALUE = 100_000;
uint16 constant TEST_STRATEGY_SHARE_PERCENT = 1_000;

contract VaultTest is Test {
    /*
    - Добавить invariant тесты
    - Сценариев с несколькими стратегиями в очереди вывода
    - Boundary значений (MIN_PERCENT, MAX_PERCENT)
    - Взаимодействия между стратегиями при выводе
    - Тестов gas consumption
    - Fuzz тестов
     */

    Erc20Mock internal erc20Mock;
    StackingMock internal stackingMock;
    Vault internal vault;
    BaseStrategyWrapper internal strategyOne;
    BaseStrategyWrapper internal strategyTwo;

    address internal manager = address(1);
    address internal keeper = address(2);
    address internal feeRecipient = address(3);

    address internal user1 = address(4);
    address internal user2 = address(5);
    address internal user3 = address(6);

    function setUp() public {
        erc20Mock = new Erc20Mock();
        stackingMock = new StackingMock(erc20Mock);
        vault = new Vault(erc20Mock, "vaultShare", "VS", manager, feeRecipient);

        strategyOne = new BaseStrategyWrapper(address(stackingMock), erc20Mock, "BaseStrategyWrapper", address(vault));
        strategyTwo = new BaseStrategyWrapper(address(stackingMock), erc20Mock, "BaseStrategyWrapper", address(vault));

        erc20Mock.mint(user1, DEFAULT_USER_BALANCE);
        erc20Mock.mint(user2, DEFAULT_USER_BALANCE);
        erc20Mock.mint(user3, DEFAULT_USER_BALANCE);

        vm.prank(manager);
        vault.grantRole(KEEPER_ROLE, keeper);
    }

    event UpdateManagementRecipient(address indexed recipient);

    event UpdateManagementFee(uint16 indexed fee);

    event UpdatePerformanceFee(address indexed strategy, uint16 indexed newFee);

    event UpdateStrategySharePercent(address indexed strategy, uint256 newPercent);

    event StrategyAdded(address indexed strategy);

    event UpdateStrategyBalance(IBaseStrategy indexed strategy, uint256 newBalance);

    event UpdateWithdrawalQueue(IBaseStrategy[MAXIMUM_STRATEGIES]);

    event StrategyMigrated(address indexed oldVersion, address indexed newVersion);

    event StrategyRemoved(address indexed strategy, uint256 totalAssets);

    event EmergencyWithdraw(uint256 timestamp, uint256 amount);

    event Reported(uint256 profit, uint256 loss, uint256 managementFees, uint256 performanceFees);

    function _setUpWithStrategyOne() internal {
        vm.startPrank(manager);
        vault.add(strategyOne, TEST_STRATEGY_SHARE_PERCENT);
    }

    function _setUpWithStrategyOneAndTwoWithMaxSharePERCENT() internal {
        vm.startPrank(manager);
        vault.add(strategyOne, MAX_PERCENT / 2);
        vault.add(strategyTwo, MAX_PERCENT / 2);
        vm.stopPrank();
    }

    function _setUpWithLiquidityStrategyOne() internal {
        _setUpWithStrategyOne();
        vault.setSharePercent(strategyOne, MAX_PERCENT);
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

    function test_withManagmentFee_report() external {
        _setUpWithLiquidityStrategyOne();
        stackingMock.updateInvest(address(strategyOne));

        uint256 expectedProfit = stackingMock.calculateProfit(TEST_INVEST_VALUE);
        uint256 strategyBalance = vault.strategyBalance(strategyOne);
        uint256 performanceFee = vault.strategyPerformanceFee(strategyOne);
        uint256 managementFee = vault.managementFee();

        uint256 period = 32 days;
        uint256 expectedPerformanceFee = vault.previewDeposit(expectedProfit * performanceFee / BPS);
        uint256 expectedManagementFee =
            ((strategyBalance + expectedProfit) * managementFee * period) / (BPS * SECONDS_PER_YEAR);

        vm.expectEmit(true, true, true, true);
        emit Reported(expectedProfit, 0, expectedManagementFee, expectedPerformanceFee);

        skip(period);
        vm.startPrank(keeper);
        vault.report(strategyOne);

        uint256 recipientBalance = vault.balanceOf(feeRecipient);
        vm.assertEq(recipientBalance, vault.previewDeposit(expectedPerformanceFee + expectedManagementFee));
    }

    function test_withLoss_report() external {
        _setUpWithLiquidityStrategyOne();
        stackingMock.setIsReturnedProfit(false);
        stackingMock.updateInvest(address(strategyOne));

        uint256 expectedLoss = stackingMock.calculateLoss(TEST_INVEST_VALUE);
        uint256 expectedPerformanceFee = 0;

        vm.expectEmit(true, true, true, true);
        emit Reported(0, expectedLoss, 0, expectedPerformanceFee);

        vm.startPrank(keeper);
        vault.report(strategyOne);

        uint256 recipientBalance = vault.balanceOf(feeRecipient);
        vm.assertEq(recipientBalance, expectedPerformanceFee);
    }

    function test_withProfit_report() external {
        _setUpWithLiquidityStrategyOne();
        stackingMock.updateInvest(address(strategyOne));

        uint256 expectedProfit = stackingMock.calculateProfit(TEST_INVEST_VALUE);
        uint256 performanceFee = vault.strategyPerformanceFee(strategyOne);

        uint256 expectedPerformanceFee = (expectedProfit * performanceFee) / BPS;

        vm.expectEmit(true, true, true, true);
        emit Reported(expectedProfit, 0, 0, expectedPerformanceFee);

        vm.startPrank(keeper);
        vault.report(strategyOne);

        uint256 recipientBalance = vault.balanceOf(feeRecipient);
        vm.assertEq(recipientBalance, vault.previewDeposit(expectedPerformanceFee));
    }

    function test_whenNotPaused_emergencyWithdraw() external {
        _setUpWithLiquidityStrategyOne();
        stackingMock.updateInvest(address(strategyOne));

        uint256 profit = stackingMock.calculateProfit(TEST_INVEST_VALUE);

        uint256 balanceVaultBefore = erc20Mock.balanceOf(address(vault));
        uint256 balanceStackingBefore = stackingMock.getBalance(address(strategyOne));
        vm.assertEq(balanceVaultBefore, 0);
        vm.assertEq(balanceStackingBefore, TEST_INVEST_VALUE);

        vm.assertFalse(strategyOne.isPaused());

        vm.startPrank(manager);
        vault.emergencyWithdraw(strategyOne);

        uint256 balanceVaultAfterEmergency = erc20Mock.balanceOf(address(vault));
        uint256 balanceStackingAfter = stackingMock.getBalance(address(strategyOne));

        vm.assertEq(balanceStackingAfter, 0);
        vm.assertEq(balanceVaultAfterEmergency, TEST_INVEST_VALUE + profit);
    }

    function test_whenPaused_emergencyWithdraw() external {
        _setUpWithLiquidityStrategyOne();
        stackingMock.updateInvest(address(strategyOne));

        uint256 profit = stackingMock.calculateProfit(TEST_INVEST_VALUE);

        vm.startPrank(address(keeper));

        uint256 balanceStrategyBefore = erc20Mock.balanceOf(address(strategyOne));
        uint256 balanceVaultBefore = erc20Mock.balanceOf(address(vault));
        vm.assertEq(balanceVaultBefore, 0);
        vm.assertEq(balanceStrategyBefore, 0);

        vault.pause(strategyOne);
        vm.stopPrank();

        uint256 balanceStrategyAfter = erc20Mock.balanceOf(address(strategyOne));
        uint256 balanceVaultAfter = erc20Mock.balanceOf(address(vault));

        vm.assertTrue(strategyOne.isPaused());
        vm.assertEq(balanceStrategyAfter, TEST_INVEST_VALUE + profit);
        vm.assertEq(balanceVaultAfter, 0);

        vm.startPrank(manager);
        vault.emergencyWithdraw(strategyOne);

        uint256 balanceStrategyAfterEmergency = erc20Mock.balanceOf(address(strategyOne));
        uint256 balanceVaultAfterEmergency = erc20Mock.balanceOf(address(vault));

        vm.assertEq(balanceStrategyAfterEmergency, 0);
        vm.assertEq(balanceVaultAfterEmergency, TEST_INVEST_VALUE + profit);
    }

    function test_strategySharePercent() external {
        _setUpWithLiquidityStrategyOne();

        uint16 sharePercent = vault.strategySharePercent(strategyOne);

        vm.assertEq(sharePercent, MAX_PERCENT);
    }

    function test_strategyBalance() external {
        _setUpWithLiquidityStrategyOne();

        uint256 balance = vault.strategyBalance(strategyOne);

        vm.assertEq(balance, TEST_INVEST_VALUE);
    }

    function test_setSharePercent() external {
        _setUpWithStrategyOne();

        vault.setSharePercent(strategyOne, MAX_PERCENT);

        uint16 sharePercent = vault.strategySharePercent(strategyOne);

        vm.assertEq(sharePercent, MAX_PERCENT);
    }

    function test_rebalance() external {
        // first
        _setUpWithLiquidityStrategyOne();

        uint256 strategyOneLastTotalAsset = strategyOne.lastTotalAssets();
        vm.assertEq(strategyOneLastTotalAsset, TEST_INVEST_VALUE);

        // second
        _depositFrom(user1);

        vm.prank(address(keeper));
        vault.rebalance(strategyOne);

        uint256 strategyOneTotalAsset = stackingMock.getBalance(address(strategyOne));
        vm.assertEq(strategyOneTotalAsset, TEST_INVEST_VALUE * 2);
    }

    function test_migrate() external {
        _setUpWithStrategyOne();

        uint16 performanceFeeOldStrategy = vault.strategyPerformanceFee(strategyOne);
        uint256 strategyBalanceOldStrategy = vault.strategyBalance(strategyOne);
        uint16 strategySharePercentOldStrategy = vault.strategySharePercent(strategyOne);

        vault.migrate(strategyOne, strategyTwo);

        uint16 performanceFeeNewStrategy = vault.strategyPerformanceFee(strategyTwo);
        uint256 strategyBalanceNewStrategy = vault.strategyBalance(strategyTwo);
        uint16 strategySharePercentNewStrategy = vault.strategySharePercent(strategyTwo);

        IBaseStrategy[MAXIMUM_STRATEGIES] memory withdrawalQueueAfter = vault.withdrawalQueue();

        vm.assertEq(address(strategyTwo), address(withdrawalQueueAfter[0]));
        vm.assertEq(performanceFeeNewStrategy, performanceFeeOldStrategy);
        vm.assertEq(strategyBalanceNewStrategy, strategyBalanceOldStrategy);
        vm.assertEq(strategySharePercentNewStrategy, strategySharePercentOldStrategy);
    }

    function test_remove() external {
        _setUpWithStrategyOne();

        IBaseStrategy[MAXIMUM_STRATEGIES] memory withdrawalQueueBefore = vault.withdrawalQueue();

        vm.assertEq(address(strategyOne), address(withdrawalQueueBefore[0]));

        vault.remove(strategyOne);

        IBaseStrategy[MAXIMUM_STRATEGIES] memory withdrawalQueueAfter = vault.withdrawalQueue();
        vm.assertEq(address(0), address(withdrawalQueueAfter[0]));
    }

    function test_notExists_remove() external {
        vm.startPrank(manager);
        vm.expectRevert(bytes("strategy not exist"));
        vault.remove(strategyOne);
    }

    function test_add() external {
        vm.startPrank(manager);
        vault.add(strategyOne, TEST_STRATEGY_SHARE_PERCENT);
    }

    function test_withoutAllowance_add() external {
        vm.prank(address(strategyOne));
        erc20Mock.approve(address(vault), 0);

        vm.startPrank(manager);
        vm.expectRevert(bytes("must allowance type(uint256).max"));
        vault.add(strategyOne, TEST_STRATEGY_SHARE_PERCENT);
    }

    function test_sameStrategy_add() external {
        vm.startPrank(manager);
        vault.add(strategyOne, TEST_STRATEGY_SHARE_PERCENT);

        vm.expectRevert(bytes("strategy exist"));
        vault.add(strategyOne, TEST_STRATEGY_SHARE_PERCENT);
    }

    function test_outOfBoundsLimited_add() external {
        vm.startPrank(manager);
        for (uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
            IBaseStrategy strategy =
                new BaseStrategyWrapper(address(stackingMock), erc20Mock, "BaseStrategyWrapper", address(vault));
            vault.add(strategy, TEST_STRATEGY_SHARE_PERCENT / uint16(MAXIMUM_STRATEGIES));
        }

        vm.expectRevert(bytes("limited of strategy"));
        vault.add(strategyOne, TEST_STRATEGY_SHARE_PERCENT);
    }

    function test_otherVaultIn_add() external {
        Vault otherVault = new Vault(erc20Mock, "", "", manager, feeRecipient);

        IBaseStrategy strategy =
            new BaseStrategyWrapper(address(stackingMock), erc20Mock, "BaseStrategyWrapper", address(otherVault));

        vm.startPrank(manager);
        vm.expectRevert(bytes("bad strategy vault in"));
        vault.add(strategy, TEST_STRATEGY_SHARE_PERCENT);
    }

    function test_unsuitableToken_add() external {
        Erc20Mock otherErc20 = new Erc20Mock();
        IBaseStrategy strategy =
            new BaseStrategyWrapper(address(stackingMock), otherErc20, "BaseStrategyWrapper", address(vault));

        vm.startPrank(manager);
        vm.expectRevert(bytes("bad strategy asset in"));
        vault.add(strategy, TEST_STRATEGY_SHARE_PERCENT);
    }

    function test_withoutRoles_add() external {
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, user1, vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.add(strategyOne, TEST_STRATEGY_SHARE_PERCENT);
    }

    function test_totalAssets() external {
        uint256 totalAssets = vault.totalAssets();

        vm.assertEq(totalAssets, 0);
        _setUpWithStrategyOne();
        vm.stopPrank();

        _depositFrom(user1);

        vm.startPrank(user1);
        totalAssets = vault.maxWithdraw(user1);
        vm.assertEq(totalAssets, TEST_INVEST_VALUE);
    }

    function test_maxWithdraw() external {
        uint256 max = vault.maxWithdraw(user1);

        vm.assertEq(max, 0);
        _setUpWithStrategyOne();
        vm.stopPrank();

        _depositFrom(user1);

        vm.startPrank(user1);
        max = vault.maxWithdraw(user1);
        vm.assertEq(max, TEST_INVEST_VALUE);
    }

    function test_maxRedeem() external {
        uint256 max = vault.maxRedeem(user1);

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

    function test_more100PERCENTFee_setPerformanceFee() external {
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

    function test_more100PERCENTFee_setManagementFee() external {
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
        vault.add(strategyOne, TEST_STRATEGY_SHARE_PERCENT);
        vault.add(strategyTwo, TEST_STRATEGY_SHARE_PERCENT);

        IBaseStrategy[MAXIMUM_STRATEGIES] memory oldWithdrawalQueue = vault.withdrawalQueue();

        IBaseStrategy[MAXIMUM_STRATEGIES] memory newWithdrawalQueue;
        newWithdrawalQueue[0] = strategyTwo;
        newWithdrawalQueue[1] = strategyOne;

        vault.setWithdrawalQueue(newWithdrawalQueue);

        newWithdrawalQueue = vault.withdrawalQueue();

        vm.assertEq(address(newWithdrawalQueue[0]), address(oldWithdrawalQueue[1]));
        vm.assertEq(address(newWithdrawalQueue[1]), address(oldWithdrawalQueue[0]));
    }

    function test_withChangeStrategy_setWithdrawalQueue() external {
        vm.startPrank(manager);
        vault.add(strategyOne, TEST_STRATEGY_SHARE_PERCENT);
        vault.add(strategyTwo, TEST_STRATEGY_SHARE_PERCENT);

        IBaseStrategy[MAXIMUM_STRATEGIES] memory newWithdrawalQueue;
        newWithdrawalQueue[0] =
            new BaseStrategyWrapper(address(stackingMock), erc20Mock, "BaseStrategyWrapper", address(vault));
        newWithdrawalQueue[1] = strategyOne;

        vm.expectRevert(bytes("Cannot use to change strategies"));
        vault.setWithdrawalQueue(newWithdrawalQueue);
    }

    function test_withdrawalQueue() external {
        _setUpWithStrategyOne();

        IBaseStrategy[MAXIMUM_STRATEGIES] memory withdrawalQueue = vault.withdrawalQueue();
        vm.assertEq(address(strategyOne), address(withdrawalQueue[0]));
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
