// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {IBaseStrategy} from "../../src/interfaces/IBaseStrategy.sol";
import {BaseStrategyWrapper} from "../wrappers/BaseStrategyWrapper.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {Erc20Mock} from "../mocks/Erc20Mock.sol";
import {StackingMock} from "../mocks/StackingMock.sol";
import {VaultMock} from "../mocks/VaultMock.sol";

import {Test} from "forge-std/Test.sol";

contract BaseStrategyWrapperTest is Test {
    string constant NAME_ASSET_TOKEN = "vaultAsset";
    string constant SYMBOL_ASSET_TOKEN = "VA";
    string constant NAME_BASE_STRATEGY_WRAPPER = "StackingStrategyWrapper";
    uint256 constant DEFAULT_BALANCE = 10_000e18;
    uint256 constant DEPOSIT_VALUE = 10_000;

    Erc20Mock erc20Mock;
    StackingMock stackingMock;
    VaultMock vaultMock;

    BaseStrategyWrapper strategyWrapper;

    address user1 = vm.addr(1);
    address user2 = vm.addr(2);
    address user3 = vm.addr(3);

    function setUp() public {
        erc20Mock = new Erc20Mock();
        stackingMock = new StackingMock(erc20Mock);
        vaultMock = new VaultMock(erc20Mock);
        strategyWrapper =
            new BaseStrategyWrapper(address(stackingMock), erc20Mock, NAME_BASE_STRATEGY_WRAPPER, address(vaultMock));

        erc20Mock.mint(address(vaultMock), DEFAULT_BALANCE);
        erc20Mock.mint(user1, DEFAULT_BALANCE);
        erc20Mock.mint(user2, DEFAULT_BALANCE);
        erc20Mock.mint(user3, DEFAULT_BALANCE);
    }

    function _strategyPushAmountFromVault(uint256 depositValue) internal {
        vaultMock.setStrategyBalance(strategyWrapper, depositValue);

        vm.startPrank(address(vaultMock));
        erc20Mock.approve(address(strategyWrapper), depositValue);
        strategyWrapper.push(depositValue);
        vm.stopPrank();
    }

    function test_supportsInterface() external view {
        bytes4 baseStrategyInterface = type(IBaseStrategy).interfaceId;
        bytes4 randomInterface = bytes4(keccak256("bu bu bu()"));

        vm.assertTrue(
            strategyWrapper.supportsInterface(baseStrategyInterface), "should support IBaseStrategy interface"
        );
    }

    function test_Constructor_ZeroAssetToken() external {
        vm.expectRevert(bytes("assetToken zero address"));
        new BaseStrategyWrapper(address(stackingMock), IERC20(address(0)), "Test", address(vaultMock));
    }

    function test_Constructor_ZeroVault() external {
        vm.expectRevert(bytes("vault zero address"));
        new BaseStrategyWrapper(address(stackingMock), erc20Mock, "Test", address(0));
    }

    function test_takeAndClose() external {
        _strategyPushAmountFromVault(DEPOSIT_VALUE);
        uint256 initialVaultBalance = erc20Mock.balanceOf(address(vaultMock));

        vm.prank(address(vaultMock));
        uint256 withdrawnAmount = strategyWrapper.takeAndClose();
        uint256 finalVaultBalance = erc20Mock.balanceOf(address(vaultMock));

        vm.assertEq(withdrawnAmount, DEPOSIT_VALUE);
        vm.assertEq(finalVaultBalance, initialVaultBalance + DEPOSIT_VALUE);
        vm.assertTrue(strategyWrapper.isPaused());
    }

    function test_NotVault_takeAndClose() external {
        vm.prank(user3);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user3, address(0))
        );
        strategyWrapper.takeAndClose();
    }

    function test_emergencyWithdraw_WhenEmpty() external {
        vm.prank(address(vaultMock));
        uint256 withdrawnAmount = strategyWrapper.emergencyWithdraw();

        vm.assertEq(withdrawnAmount, 0, "should return 0");
        vm.assertTrue(strategyWrapper.isPaused(), "should be paused");
    }

    function test_emergencyWithdraw_WithBalance() external {
        _strategyPushAmountFromVault(DEPOSIT_VALUE);
        uint256 initialVaultBalance = erc20Mock.balanceOf(address(vaultMock));

        vm.prank(address(vaultMock));
        uint256 withdrawnAmount = strategyWrapper.emergencyWithdraw();
        uint256 finalVaultBalance = erc20Mock.balanceOf(address(vaultMock));

        vm.assertEq(withdrawnAmount, DEPOSIT_VALUE, "should return deposited amount");
        vm.assertEq(finalVaultBalance, initialVaultBalance + DEPOSIT_VALUE, "vault should receive assets");
        vm.assertTrue(strategyWrapper.isPaused(), "should be paused");
    }

    function test_NotVault_emergencyWithdraw() external {
        vm.prank(user3);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user3, address(0))
        );
        strategyWrapper.emergencyWithdraw();
    }

    function test_RebalanceAndReport_NotKeeper() external {
        vm.startPrank(user3);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, user3, strategyWrapper.KEEPER_ROLE()
            )
        );
        strategyWrapper.rebalanceAndReport();
    }

    function test_RebalanceAndReport_Success() external {
        _strategyPushAmountFromVault(DEPOSIT_VALUE);
        stackingMock.updateInvest(address(strategyWrapper));

        vm.mockCall(
            address(vaultMock), abi.encodeWithSignature("rebalance(address)", address(strategyWrapper)), abi.encode()
        );

        uint256 expectedProfit = 100;
        uint256 expectedLoss = 0;
        uint256 expectedBalance = DEPOSIT_VALUE + expectedProfit;

        vm.mockCall(
            address(vaultMock),
            abi.encodeWithSignature("report(address)", address(strategyWrapper)),
            abi.encode(expectedProfit, expectedLoss, expectedBalance)
        );

        vm.prank(address(vaultMock));
        (uint256 profit, uint256 loss, uint256 balance) = strategyWrapper.rebalanceAndReport();

        vm.assertEq(profit, expectedProfit, "bad profit");
        vm.assertEq(loss, expectedLoss, "bad loss");
        vm.assertEq(balance, expectedBalance, "bad balance");
    }

    function test_report_WithLoss() external {
        _strategyPushAmountFromVault(DEPOSIT_VALUE);
        stackingMock.updateInvest(address(strategyWrapper));

        vm.prank(address(vaultMock));
        strategyWrapper.report();

        stackingMock.setIsReturnedProfit(false);
        stackingMock.updateInvest(address(strategyWrapper));

        uint256 expectedLoss = stackingMock.calculateProfit(DEPOSIT_VALUE);

        vm.expectEmit(true, true, true, false);
        emit Report(block.timestamp, 0, expectedLoss);

        vm.prank(address(vaultMock));
        (uint256 profit, uint256 loss) = strategyWrapper.report();

        vm.assertEq(profit, 0, "should 0");
        vm.assertEq(loss, expectedLoss, "incorrect loss");
    }

    function test_report_ZeroProfitZeroLoss() external {
        _strategyPushAmountFromVault(DEPOSIT_VALUE);

        vm.prank(address(vaultMock));
        (uint256 profit, uint256 loss) = strategyWrapper.report();

        vm.assertEq(profit, 0, "should bu 0");
        vm.assertEq(loss, 0, "should be 0 ");
    }

    function test_pull_InsufficientAssets() external {
        _strategyPushAmountFromVault(DEPOSIT_VALUE);

        vm.prank(address(vaultMock));
        vm.expectRevert(bytes("insufficient assets"));
        strategyWrapper.pull(DEPOSIT_VALUE + 1);
    }

    function test_report() external {
        _strategyPushAmountFromVault(DEPOSIT_VALUE);
        stackingMock.updateInvest(address(strategyWrapper));

        // first profit > 0
        vm.startPrank(address(vaultMock));
        (uint256 profit, uint256 loss) = strategyWrapper.report();

        vm.assertEq(loss, 0);

        uint256 amount = stackingMock.calculateProfit(DEPOSIT_VALUE);
        uint256 lastTotalAsset = strategyWrapper.lastTotalAssets();

        vm.assertEq(profit, amount);
        vm.assertEq(DEPOSIT_VALUE + profit, lastTotalAsset);

        // second profit > 0
        erc20Mock.approve(address(strategyWrapper), DEPOSIT_VALUE);
        strategyWrapper.push(DEPOSIT_VALUE);
        stackingMock.updateInvest(address(strategyWrapper));

        (uint256 profitTwo,) = strategyWrapper.report();
        uint256 lastTotalAssetTwo = strategyWrapper.lastTotalAssets();
        uint256 expectedResult = DEPOSIT_VALUE * 2 + profitTwo + profit;

        vm.assertEq(profitTwo, profit * 2);
        vm.assertEq(expectedResult, lastTotalAssetTwo);

        stackingMock.setIsReturnedProfit(false);

        erc20Mock.approve(address(strategyWrapper), DEPOSIT_VALUE);
        strategyWrapper.push(DEPOSIT_VALUE);
        stackingMock.updateInvest(address(strategyWrapper));

        (, uint256 lossThree) = strategyWrapper.report();
        uint256 lastTotalAssetThree = strategyWrapper.lastTotalAssets();

        expectedResult = DEPOSIT_VALUE * 3 + profitTwo + profit - lossThree;

        vm.assertEq(expectedResult, lastTotalAssetThree);
    }

    function test_NotVault_push() external {
        vm.startPrank(user3);
        erc20Mock.approve(address(strategyWrapper), DEPOSIT_VALUE);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user3, address(0))
        );

        strategyWrapper.push(DEPOSIT_VALUE);
    }

    function test_push() external {
        _strategyPushAmountFromVault(DEPOSIT_VALUE);

        uint256 check = strategyWrapper.lastTotalAssets();
        vm.assertEq(check, DEPOSIT_VALUE);

        uint256 balanceVaultAfter = erc20Mock.balanceOf(address(vaultMock));
        vm.assertEq(DEFAULT_BALANCE - DEPOSIT_VALUE, balanceVaultAfter);

        uint256 balanceStacking = erc20Mock.balanceOf(address(stackingMock));
        vm.assertEq(DEPOSIT_VALUE, balanceStacking);
    }

    function test_NotVault_pull() external {
        _strategyPushAmountFromVault(DEPOSIT_VALUE);

        vm.prank(user3);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user3, address(0))
        );

        strategyWrapper.pull(DEPOSIT_VALUE);
    }

    function test_pull() external {
        _strategyPushAmountFromVault(DEPOSIT_VALUE);

        uint256 balance = stackingMock.getBalance(address(strategyWrapper));
        vm.assertEq(DEPOSIT_VALUE, balance);

        stackingMock.updateInvest(address(strategyWrapper));
        uint256 balanceAndResullt = stackingMock.balanceAndResult(address(strategyWrapper));

        vm.prank(address(vaultMock));
        strategyWrapper.pull(DEPOSIT_VALUE);

        uint256 calculatedProfit = stackingMock.calculateProfit(DEPOSIT_VALUE);

        vm.assertEq(balanceAndResullt - balance, calculatedProfit);
    }

    function test_pause() external {
        vm.prank(address(vaultMock));
        strategyWrapper.pause();
    }

    function test_NotOwner_pause() external {
        vm.prank(user3);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user3, address(0))
        );
        strategyWrapper.pause();
    }

    function test_WhenPaused_pause() external {
        vm.startPrank(address(vaultMock));
        strategyWrapper.pause();

        strategyWrapper.pause();
    }

    function test_unpause() external {
        vm.startPrank(address(vaultMock));
        strategyWrapper.pause();
        strategyWrapper.unpause();
    }

    function test_NotOwner_unpause() external {
        vm.prank(address(vaultMock));
        strategyWrapper.pause();
        vm.prank(user3);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user3, address(0))
        );
        strategyWrapper.unpause();
    }

    //////////////////////////////////////////
    //                view                  //
    //////////////////////////////////////////

    function test_isPaused() external {
        bool check = strategyWrapper.isPaused();
        vm.assertEq(check, false);

        vm.startPrank(address(vaultMock));
        strategyWrapper.pause();

        check = strategyWrapper.isPaused();
        vm.assertEq(check, true);
    }

    function test_asset() external view {
        address check = strategyWrapper.asset();
        vm.assertEq(check, address(erc20Mock));
    }

    function test_vault() external view {
        address check = strategyWrapper.vault();
        vm.assertEq(check, address(vaultMock));
    }

    function test_lastTotalAssets() external {
        uint256 check = strategyWrapper.lastTotalAssets();
        vm.assertEq(check, 0);

        uint256 newTotalAsset = 100_001;
        vm.startPrank(address(vaultMock));
        erc20Mock.approve(address(strategyWrapper), newTotalAsset);
        strategyWrapper.push(newTotalAsset);
        // vm.store(address(strategyWrapper), bytes32(uint256(2)), bytes32(newTotalAsset));

        check = strategyWrapper.lastTotalAssets();
        vm.assertEq(check, newTotalAsset);
    }

    function test_name() external view {
        string memory check = strategyWrapper.name();
        vm.assertEq(check, NAME_BASE_STRATEGY_WRAPPER);
    }

    //////////////////////////////////////////
    //             events                   //
    //////////////////////////////////////////

    event Pull(uint256 assetPull);

    event Push(uint256 assetPush);

    event Report(uint256 indexed time, uint256 indexed profit, uint256 indexed loss);

    event StrategyUnpaused(uint256 indexed timestamp);

    event StrategyPaused(uint256 indexed timestamp);

    event EmergencyWithdraw(uint256 indexed timestamp, uint256 indexed amount);

    function test_eventPull() external {
        _strategyPushAmountFromVault(DEPOSIT_VALUE);

        vm.startPrank(address(vaultMock));
        (uint256 profit, uint256 loss) = strategyWrapper.report();

        vm.expectEmit(true, false, false, false);
        emit Pull(DEPOSIT_VALUE + profit - loss);

        strategyWrapper.pull(DEPOSIT_VALUE);
    }

    function test_eventPush() external {
        vm.startPrank(address(vaultMock));
        erc20Mock.approve(address(strategyWrapper), DEPOSIT_VALUE);

        vm.expectEmit(true, false, false, false);
        emit Push(DEPOSIT_VALUE);
        strategyWrapper.push(DEPOSIT_VALUE);
    }

    function test_eventReport() external {
        _strategyPushAmountFromVault(DEPOSIT_VALUE);
        stackingMock.updateInvest(address(strategyWrapper));

        uint256 expercterProfit = stackingMock.calculateProfit(DEPOSIT_VALUE);
        uint256 expercterLoss = 0;

        vm.expectEmit(true, true, true, false);
        emit Report(block.timestamp, expercterProfit, expercterLoss);

        vm.prank(address(vaultMock));
        (uint256 profit, uint256 loss) = strategyWrapper.report();

        vm.assertEq(expercterProfit, profit);
        vm.assertEq(expercterLoss, loss);
    }

    function test_eventPause() external {
        vm.expectEmit(true, false, false, false);

        emit StrategyPaused(block.timestamp);
        vm.prank(address(vaultMock));
        strategyWrapper.pause();
    }

    function test_eventUnpause() external {
        vm.startPrank(address(vaultMock));
        strategyWrapper.pause();

        vm.expectEmit(true, false, false, false);
        emit StrategyUnpaused(block.timestamp);
        strategyWrapper.unpause();
    }
}
