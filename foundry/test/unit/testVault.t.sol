// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {IBaseStrategy} from "../../src/interfaces/IBaseStrategy.sol";
import {Vault} from "../../src/Vault.sol";
import {IVault} from "../../src/interfaces/IVault.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

import {Erc20Mock} from "../mocks/Erc20Mock.sol";
import {StackingMock} from "../mocks/StackingMock.sol";
import {BaseStrategyWrapper} from "../wrappers/BaseStrategyWrapper.sol";

import {Test} from "forge-std/Test.sol";
import "forge-std/Test.sol";

uint256 constant BPS = 10_000;
uint16 constant DEFAULT_FEE = 100;
uint16 constant MAX_PERCENT = 10_000;
uint16 constant MIN_PERCENT = 1;
uint256 constant MAXIMUM_STRATEGIES = 20;
bytes32 constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
bytes32 constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

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

    function _setUpWithStrategyOneAndTwoWithMaxSharePercent() internal {
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

    function test_supportsInterface() external view {
        bytes4 vaultInterface = type(IVault).interfaceId;
        bytes4 erc4626Interface = type(IERC4626).interfaceId;
        bytes4 erc20Interface = type(IERC20).interfaceId;
        bytes4 erc20MetadataInterface = type(IERC20Metadata).interfaceId;
        bytes4 accessControlInterface = type(IAccessControl).interfaceId;
        bytes4 randomInterface = bytes4(keccak256("random()"));

        vm.assertTrue(vault.supportsInterface(vaultInterface), "should support IVault");
        vm.assertTrue(vault.supportsInterface(erc4626Interface), "should support IERC4626");
        vm.assertTrue(vault.supportsInterface(erc20Interface), "should support IERC20");
        vm.assertTrue(vault.supportsInterface(erc20MetadataInterface), "should support IERC20Metadata");
        vm.assertTrue(vault.supportsInterface(accessControlInterface), "should support IAccessControl");

        vm.assertFalse(vault.supportsInterface(randomInterface), "should not support random interface");
    }

    function test_constructorZeroAddresses() external {
        vm.expectRevert("assetToken zero address");
        new Vault(IERC20(address(0)), "test", "TST", manager, feeRecipient);

        vm.expectRevert("manager zero address");
        new Vault(erc20Mock, "test", "TST", address(0), feeRecipient);

        vm.expectRevert("feeRecipient zero address");
        new Vault(erc20Mock, "test", "TST", manager, address(0));
    }

    function test_withManagementFeeReport() external {
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

    function test_withLossReport() external {
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

    function test_strategyGrantRole() external {
        _setUpWithStrategyOne();
        vm.stopPrank();

        bytes32 testRole = keccak256("TEST_ROLE");
        address testAccount = address(0x123);

        vm.prank(manager);
        vault.strategyGrantRole(strategyOne, testRole, testAccount);

        bool hasRole = strategyOne.hasRole(testRole, testAccount);
        vm.assertTrue(hasRole);
    }

    function test_strategyGrantRoleSelf() external {
        _setUpWithStrategyOne();
        vm.stopPrank();

        bytes32 testRole = keccak256("TEST_ROLE");

        vm.prank(manager);
        vault.strategyGrantRole(strategyOne, testRole, address(vault));
    }

    function test_strategyRevokeRole() external {
        _setUpWithStrategyOne();
        vm.stopPrank();

        bytes32 testRole = keccak256("TEST_ROLE");
        address testAccount = address(0x123);

        vm.startPrank(manager);
        vault.strategyGrantRole(strategyOne, testRole, testAccount);

        vault.strategyRevokeRole(strategyOne, testRole, testAccount);
        vm.stopPrank();

        bool hasRole = strategyOne.hasRole(testRole, testAccount);
        vm.assertFalse(hasRole, "should revoke");
    }

    function test_strategyRevokeRoleSelf() external {
        _setUpWithStrategyOne();
        vm.stopPrank();

        bytes32 testRole = keccak256("TEST_ROLE");

        vm.prank(manager);
        vault.strategyRevokeRole(strategyOne, testRole, address(vault));
    }

    function test_notAdminStrategyGrantRole() external {
        _setUpWithStrategyOne();
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, user1, vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.strategyGrantRole(strategyOne, keccak256("TEST_ROLE"), user1);
    }

    function test_reportWhenLossExceedsBalance() external {
        _setUpWithLiquidityStrategyOne();

        uint256 expectLoss = stackingMock.calculateLoss(TEST_INVEST_VALUE);
        stackingMock.setIsReturnedProfit(false);
        stackingMock.updateInvest(address(strategyOne));

        vm.prank(keeper);
        (uint256 profit, uint256 loss, uint256 balance) = vault.report(strategyOne);

        vm.assertEq(profit, 0, "should have 0");
        vm.assertEq(loss, expectLoss, "should report correct loss");
    }

    function test_reportFeeExceedsProfit() external {
        _setUpWithLiquidityStrategyOne();

        vm.startPrank(manager);
        vault.setPerformanceFee(strategyOne, 9000);
        vault.setManagementFee(5000); // 50%
        vm.stopPrank();

        uint256 expectProfit = stackingMock.calculateLoss(TEST_INVEST_VALUE);
        uint256 smallProfit = TEST_INVEST_VALUE / 10;
        stackingMock.updateInvest(address(strategyOne));

        skip(365 days);

        vm.prank(keeper);
        (uint256 profit, uint256 loss, uint256 balance) = vault.report(strategyOne);

        vm.assertEq(loss, 0, "should have 0 loss");
        vm.assertEq(profit, smallProfit, "should have small profit");

        uint256 feeRecipientBalance = vault.balanceOf(feeRecipient);
        uint256 expectedFeeShares = vault.previewDeposit(smallProfit);
        vm.assertLe(feeRecipientBalance, expectedFeeShares, "fee should not exceed profit");
    }

    function test_reportWhenLossGreaterThanBalance() external {
        _setUpWithLiquidityStrategyOne();

        uint256 balanceBefore = vault.strategyBalance(strategyOne);
        uint256 bigLoss = balanceBefore * 2;

        vm.mockCall(address(strategyOne), abi.encodeWithSelector(strategyOne.report.selector), abi.encode(0, bigLoss));

        vm.prank(keeper);
        (uint256 profit, uint256 loss, uint256 balance) = vault.report(strategyOne);
        vm.clearMockedCalls();

        vm.assertEq(profit, 0, "should have 0 profit");
        vm.assertEq(loss, bigLoss, "should report huge loss");
        vm.assertGt(loss, balanceBefore, "loss should be greater than initial balance");
        vm.assertEq(balance, 0, "balance should be 0 when loss exceeds");
    }

    function test_withProfitReport() external {
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

    function test_whenNotPausedEmergencyWithdraw() external {
        _setUpWithLiquidityStrategyOne();
        stackingMock.updateInvest(address(strategyOne));

        uint256 profit = stackingMock.calculateProfit(TEST_INVEST_VALUE);

        uint256 balanceVaultBefore = erc20Mock.balanceOf(address(vault));
        uint256 balanceStackingBefore = stackingMock.getBalance(address(strategyOne));
        vm.assertEq(balanceVaultBefore, 0);
        vm.assertEq(balanceStackingBefore, TEST_INVEST_VALUE);

        vm.assertFalse(strategyOne.isPaused());

        vm.startPrank(manager);
        vault.grantRole(vault.EMERGENCY_ADMIN_ROLE(), manager);
        vault.emergencyWithdraw(strategyOne);

        uint256 balanceVaultAfterEmergency = erc20Mock.balanceOf(address(vault));
        uint256 balanceStackingAfter = stackingMock.getBalance(address(strategyOne));

        vm.assertEq(balanceStackingAfter, 0);
        vm.assertEq(balanceVaultAfterEmergency, TEST_INVEST_VALUE + profit);
    }

    function test_whenPausedEmergencyWithdraw() external {
        _setUpWithLiquidityStrategyOne();
        stackingMock.updateInvest(address(strategyOne));

        uint256 profit = stackingMock.calculateProfit(TEST_INVEST_VALUE);

        vm.startPrank(address(keeper));
        uint256 balanceStrategyBefore = erc20Mock.balanceOf(address(strategyOne));
        uint256 balanceVaultBefore = erc20Mock.balanceOf(address(vault));

        vm.assertEq(balanceVaultBefore, 0);
        vm.assertEq(balanceStrategyBefore, 0);
        vm.stopPrank();

        vm.prank(address(vault));
        strategyOne.pause();

        uint256 balanceStrategyAfter = erc20Mock.balanceOf(address(strategyOne));
        uint256 balanceVaultAfter = erc20Mock.balanceOf(address(vault));

        vm.assertTrue(strategyOne.isPaused());
        vm.assertEq(balanceStrategyAfter, TEST_INVEST_VALUE + profit);
        vm.assertEq(balanceVaultAfter, 0);

        vm.startPrank(manager);
        vault.grantRole(vault.EMERGENCY_ADMIN_ROLE(), manager);
        vault.emergencyWithdraw(strategyOne);

        uint256 balanceStrategyAfterEmergency = erc20Mock.balanceOf(address(strategyOne));
        uint256 balanceVaultAfterEmergency = erc20Mock.balanceOf(address(vault));

        vm.assertEq(balanceStrategyAfterEmergency, 0);
        vm.assertEq(balanceVaultAfterEmergency, TEST_INVEST_VALUE + profit);
    }

    function test_setSharePercentExceeds100Percent() external {
        vm.startPrank(manager);
        vault.add(strategyOne, MAX_PERCENT / 2);
        vault.add(strategyTwo, MAX_PERCENT / 2);

        vm.expectRevert(bytes("total share <= 100%"));
        vault.setSharePercent(strategyOne, (MAX_PERCENT / 2) + 1);
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

    function test_rebalanceWithdrawExcess() external {
        _setUpWithStrategyOne();
        vault.setSharePercent(strategyOne, MAX_PERCENT);
        vm.stopPrank();

        _depositFrom(user2);

        vm.prank(address(keeper));
        vault.rebalance(strategyOne);

        uint16 newSharePercent = MAX_PERCENT / 2;
        vm.prank(manager);
        vault.setSharePercent(strategyOne, newSharePercent);

        uint256 expectedWithdrawAmount = TEST_INVEST_VALUE / 2;

        vm.prank(keeper);
        vault.rebalance(strategyOne);

        uint256 strategyBalance = vault.strategyBalance(strategyOne);
        uint256 expectedBalance = TEST_INVEST_VALUE - expectedWithdrawAmount;
        uint256 vaultBalance = erc20Mock.balanceOf(address(vault));

        vm.assertEq(strategyBalance, expectedBalance, "should withdraw excess from strategy");
        vm.assertEq(vaultBalance, expectedWithdrawAmount, "vault should have withdrawn assets");
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

    function test_notExistsRemove() external {
        vm.startPrank(manager);
        vm.expectRevert(bytes("strategy not exist"));
        vault.remove(strategyOne);
    }

    function test_add() external {
        vm.startPrank(manager);
        vault.add(strategyOne, TEST_STRATEGY_SHARE_PERCENT);
    }

    function test_withoutAllowanceAdd() external {
        vm.prank(address(strategyOne));
        erc20Mock.approve(address(vault), 0);

        vm.startPrank(manager);
        vm.expectRevert(bytes("must allowance type(uint256).max"));
        vault.add(strategyOne, TEST_STRATEGY_SHARE_PERCENT);
    }

    function test_sameStrategyAdd() external {
        vm.startPrank(manager);
        vault.add(strategyOne, TEST_STRATEGY_SHARE_PERCENT);

        vm.expectRevert(bytes("strategy exist"));
        vault.add(strategyOne, TEST_STRATEGY_SHARE_PERCENT);
    }

    function test_outOfBoundsLimitedAdd() external {
        vm.startPrank(manager);
        for (uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
            IBaseStrategy strategy =
                new BaseStrategyWrapper(address(stackingMock), erc20Mock, "BaseStrategyWrapper", address(vault));
            vault.add(strategy, TEST_STRATEGY_SHARE_PERCENT / uint16(MAXIMUM_STRATEGIES));
        }

        vm.expectRevert(bytes("limited of strategy"));
        vault.add(strategyOne, TEST_STRATEGY_SHARE_PERCENT);
    }

    function test_otherVaultInAdd() external {
        Vault otherVault = new Vault(erc20Mock, "", "", manager, feeRecipient);

        IBaseStrategy strategy =
            new BaseStrategyWrapper(address(stackingMock), erc20Mock, "BaseStrategyWrapper", address(otherVault));

        vm.startPrank(manager);
        vm.expectRevert(bytes("bad strategy vault in"));
        vault.add(strategy, TEST_STRATEGY_SHARE_PERCENT);
    }

    function test_redeem() external {
        _setUpWithLiquidityStrategyOne();

        vm.prank(user2);
        uint256 assets = vault.redeem(TEST_INVEST_VALUE, user2, user2);
        uint256 expectedAssets = vault.previewRedeem(TEST_INVEST_VALUE);

        vm.assertEq(assets, expectedAssets);
        vm.assertEq(vault.balanceOf(user2), 0);
    }

    function test_redeemWithMultipleStrategies() external {
        _setUpWithStrategyOneAndTwoWithMaxSharePercent();

        _depositFrom(user1);

        vm.prank(keeper);
        vault.rebalance(strategyOne);

        vm.prank(keeper);
        vault.rebalance(strategyTwo);

        uint256 sharesToRedeem = vault.balanceOf(user1) / 2;
        vm.prank(user1);
        uint256 assets = vault.redeem(sharesToRedeem, user1, user1);

        vm.assertEq(assets, vault.previewRedeem(sharesToRedeem), "should redeem correct amount");
    }

    function test_withdraw() external {
        _setUpWithLiquidityStrategyOne();
        uint256 shares = TEST_INVEST_VALUE;
        uint256 assets = vault.previewRedeem(shares);

        vm.prank(user2);
        uint256 withdrawn = vault.withdraw(assets, user2, user2);

        vm.assertEq(withdrawn, assets, "should withdraw correct amount");
        vm.assertEq(erc20Mock.balanceOf(user2), DEFAULT_USER_BALANCE, "user should get assets");
        vm.assertEq(vault.balanceOf(user2), 0, "user shares should be burned");
    }

    function test_withdrawWithEmptyStrategyInQueue() external {
        _setUpWithStrategyOneAndTwoWithMaxSharePercent();

        _depositFrom(user1);

        vm.prank(keeper);
        vault.rebalance(strategyOne);

        uint256 assets = vault.previewRedeem(TEST_INVEST_VALUE);

        vm.prank(user1);
        uint256 withdrawn = vault.withdraw(assets, user1, user1);

        vm.assertEq(withdrawn, assets, "should withdraw from non-empty strategy");
        vm.assertEq(vault.strategyBalance(strategyOne), 0, "first strategy should be empty");
        vm.assertEq(vault.strategyBalance(strategyTwo), 0, "second strategy should remain empty");
    }

    function test_withdrawWithEmptyQueue() external {
        _depositFrom(user1);
        uint256 assets = vault.previewRedeem(TEST_INVEST_VALUE);

        vm.prank(user1);
        uint256 withdrawn = vault.withdraw(assets, user1, user1);

        vm.assertEq(withdrawn, assets, "should withdraw from vault balance");
        vm.assertEq(erc20Mock.balanceOf(address(vault)), 0, "vault should be empty");
    }

    function test_withdrawSkipZeroBalanceStrategy() external {
        _setUpWithStrategyOneAndTwoWithMaxSharePercent();

        _depositFrom(user1);

        vm.prank(keeper);
        vault.rebalance(strategyTwo);

        uint256 assets = vault.previewRedeem(TEST_INVEST_VALUE);
        vm.prank(user1);
        uint256 withdrawn = vault.withdraw(assets, user1, user1);

        vm.assertEq(withdrawn, assets, "should withdraw successfully");
        vm.assertEq(vault.strategyBalance(strategyOne), 0, "strategyOne should remain empty");
        vm.assertEq(vault.strategyBalance(strategyTwo), 0, "strategyTwo should be empty after withdrawal");
    }

    function test_withdrawFromMultipleStrategies() external {
        _setUpWithStrategyOneAndTwoWithMaxSharePercent();

        uint256 largeDeposit = TEST_INVEST_VALUE * 10;
        erc20Mock.mint(user1, largeDeposit);

        vm.startPrank(user1);
        erc20Mock.approve(address(vault), largeDeposit);
        vault.deposit(largeDeposit, user1);
        vm.stopPrank();

        vm.startPrank(keeper);
        vault.rebalance(strategyOne);
        vault.rebalance(strategyTwo);
        vm.stopPrank();

        uint256 withdrawAmount = vault.strategyBalance(strategyOne) + (vault.strategyBalance(strategyTwo) / 2);
        vm.prank(user1);
        uint256 withdrawn = vault.withdraw(withdrawAmount, user1, user1);

        vm.assertEq(withdrawn, withdrawAmount, "should withdraw from multiple strategies");
        vm.assertLt(vault.strategyBalance(strategyOne), withdrawAmount, "should use both strategies");
    }

    function test_withdrawMoreThanVaultBalance() external {
        _setUpWithLiquidityStrategyOne();
        uint256 assets = TEST_INVEST_VALUE;

        vm.prank(user2);
        uint256 withdrawn = vault.withdraw(assets, user2, user2);

        vm.assertEq(withdrawn, assets, "should withdraw");
        vm.assertEq(strategyOne.lastTotalAssets(), 0, "should be empty");
    }

    function test_withdrawWithoutStrategyBalance() external {
        _setUpWithStrategyOne();
        vm.stopPrank();
        _depositFrom(user1);

        uint256 assets = vault.previewRedeem(TEST_INVEST_VALUE);
        vm.prank(user1);
        vault.withdraw(assets, user1, user1);

        vm.assertEq(erc20Mock.balanceOf(address(vault)), 0, "should be empty");
        vm.assertEq(vault.strategyBalance(strategyOne), 0, "should be empty");
    }

    function test_unsuitableTokenAdd() external {
        Erc20Mock otherErc20 = new Erc20Mock();
        IBaseStrategy strategy =
            new BaseStrategyWrapper(address(stackingMock), otherErc20, "BaseStrategyWrapper", address(vault));

        vm.startPrank(manager);
        vm.expectRevert(bytes("bad strategy asset in"));
        vault.add(strategy, TEST_STRATEGY_SHARE_PERCENT);
    }

    function test_withoutRolesAdd() external {
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

    function test_totalAssetsWithPausedStrategy() external {
        _setUpWithLiquidityStrategyOne();

        uint256 totalBeforePause = vault.totalAssets();
        vm.assertEq(totalBeforePause, TEST_INVEST_VALUE, "bad strategy balance");

        vm.prank(address(vault));
        strategyOne.pause();

        uint256 totalAfterPause = vault.totalAssets();

        vm.assertEq(totalAfterPause, 0, "when paused must be 0");
        vm.assertEq(vault.strategyBalance(strategyOne), TEST_INVEST_VALUE, "strategy balance should remain");
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
        vault.grantRole(PAUSER_ROLE, keeper);
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
        vault.grantRole(PAUSER_ROLE, keeper);
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

    function test_more100PercentFeeSetPerformanceFee() external {
        _setUpWithStrategyOne();

        uint16 newFee = 10_001;
        vm.expectRevert(bytes("max % is 100"));
        vault.setPerformanceFee(strategyOne, newFee);
    }

    function test_zeroFeeSetPerformanceFee() external {
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

    function test_more100PercentFeeSetManagementFee() external {
        _setUpWithStrategyOne();

        uint16 newFee = 10_001;
        vm.expectRevert(bytes("max % is 100"));
        vault.setManagementFee(newFee);
    }

    function test_zeroFeeSetManagementFee() external {
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

    function test_zeroAddressSetFeeRecipient() external {
        _setUpWithStrategyOne();
        vm.expectRevert(bytes("zero address"));
        vault.setFeeRecipient(address(0));
    }

    function test_performanceFee() external {
        _setUpWithStrategyOne();

        uint16 fee = vault.strategyPerformanceFee(strategyOne);
        vm.assertEq(fee, DEFAULT_FEE);
    }

    function test_setWithdrawalQueueWithZeroAddress() external {
        vm.startPrank(manager);
        vault.add(strategyOne, TEST_STRATEGY_SHARE_PERCENT);

        IBaseStrategy[MAXIMUM_STRATEGIES] memory newQueue;
        newQueue[0] = IBaseStrategy(address(0));

        vm.expectRevert(bytes("Cannot use to remove"));
        vault.setWithdrawalQueue(newQueue);
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

    function test_withChangeStrategySetWithdrawalQueue() external {
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
