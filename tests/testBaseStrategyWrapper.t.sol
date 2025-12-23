// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {BaseStrategyWrapper} from "./wrappers/BaseStrategyWrapper.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import {Erc20Mock} from "./mocks/Erc20Mock.sol";
import {StackingMock} from "./mocks/StackingMock.sol";
import {VaultMock} from "./mocks/VaultMock.sol";

import {Test} from "forge-std/Test.sol"; 

contract BaseStrategyWrapperTest is Test{
    string constant NAME_ASSET_TOKEN = "vaultAsset";
    string constant SYMBOL_ASSET_TOKEN = "VA";
    string constant NAME_BASE_STRATEGY_WRAPPER = "StackingStrategyWrapper";
    uint constant DEFAULT_BALANCE = 10_000e18;

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
        strategyWrapper = new BaseStrategyWrapper(stackingMock, erc20Mock, NAME_BASE_STRATEGY_WRAPPER, address(vaultMock));

        erc20Mock.mint(address(vaultMock), DEFAULT_BALANCE);
        erc20Mock.mint(user1, DEFAULT_BALANCE);
        erc20Mock.mint(user2, DEFAULT_BALANCE);
        erc20Mock.mint(user3, DEFAULT_BALANCE);

    }

    function strate_push10000FromVaultgyInfo(uint depositValue) internal {
        vaultMock.setStrategyBalance(strategyWrapper, depositValue);

        vm.startPrank(address(vaultMock));
        erc20Mock.approve(address(strategyWrapper), depositValue);
        strategyWrapper.push(depositValue);
        vm.stopPrank();
    }

    function test_BadSender_reportAndInvest() external {
        uint depositValue = 10_000;
        strate_push10000FromVaultgyInfo(depositValue);
        
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, strategyWrapper.KEEPER_ROLE()));
        strategyWrapper.reportAndInvest();
    }

    function test_Keeper_reportAndInvest() external {
        uint depositValue = 10_000;
        strate_push10000FromVaultgyInfo(depositValue);

        vm.startPrank(address(vaultMock));
        strategyWrapper.grantRole(strategyWrapper.KEEPER_ROLE(), user1);
        vm.stopPrank();

        uint totalAsset = strategyWrapper.lastTotalAssets();
        uint256 amount = stackingMock.calculateProfit(depositValue);

        vm.startPrank(user1);
        strategyWrapper.reportAndInvest();

        uint totalAssetAfter = strategyWrapper.lastTotalAssets();

        vm.assertEq(totalAsset + amount, totalAssetAfter);
    }

    function test_reportAndInvest() external {
        uint depositValue = 10_000;
        strate_push10000FromVaultgyInfo(depositValue);
        
        assertTrue(strategyWrapper.hasRole(strategyWrapper.DEFAULT_ADMIN_ROLE(), address(vaultMock)));

        uint totalAsset = strategyWrapper.lastTotalAssets();
        uint256 amount = stackingMock.calculateProfit(depositValue);

        vm.startPrank(address(vaultMock));
        strategyWrapper.reportAndInvest();

        uint totalAssetAfter = strategyWrapper.lastTotalAssets();

        vm.assertEq(totalAsset + amount, totalAssetAfter);
    }

    function test_report() external {
        uint depositValue = 10_000;
        strate_push10000FromVaultgyInfo(depositValue);

        // first profit > 0
        vm.startPrank(address(vaultMock));
        (uint256 profit, uint loss) = strategyWrapper.report();

        vm.assertEq(loss, 0);

        uint256 amount = stackingMock.calculateProfit(depositValue);
        uint lastTotalAsset = strategyWrapper.lastTotalAssets();

        vm.assertEq(profit, amount);
        vm.assertEq(depositValue + profit, lastTotalAsset);

        // second profit > 0
        erc20Mock.approve(address(strategyWrapper), depositValue);
        strategyWrapper.push(depositValue);

        (uint256 profitTwo,) = strategyWrapper.report();
        uint lastTotalAssetTwo = strategyWrapper.lastTotalAssets();
        uint expectedResult = depositValue * 2 + profitTwo + profit;

        vm.assertEq(profitTwo, profit);
        vm.assertEq(expectedResult, lastTotalAssetTwo);

        // thrid loss > 0
        erc20Mock.approve(address(strategyWrapper), depositValue);
        strategyWrapper.push(depositValue);

        stackingMock.setIsReturnedProfit(false);

        (, uint256 lossThree) = strategyWrapper.report();
        uint lastTotalAssetThree = strategyWrapper.lastTotalAssets();

        expectedResult = depositValue * 3 + profitTwo + profit - lossThree;
        
        vm.assertEq(expectedResult, lastTotalAssetThree);
    }

    function test_NotVault_push() external {
        uint depositValue = 10_000;

        vm.startPrank(user3);
        erc20Mock.approve(address(strategyWrapper), depositValue);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user3, address(0)));

        strategyWrapper.push(depositValue);
    }

    function test_push() external {
        uint depositValue = 10_000;

        strate_push10000FromVaultgyInfo(depositValue);

        uint check = strategyWrapper.lastTotalAssets();
        vm.assertEq(check, depositValue);

        uint balanceVaultAfter = erc20Mock.balanceOf(address(vaultMock));
        vm.assertEq(DEFAULT_BALANCE - depositValue, balanceVaultAfter);

        uint balanceStacking = erc20Mock.balanceOf(address(stackingMock));
        vm.assertEq(depositValue, balanceStacking);
    }

    function test_NotVault_pull() external {
        uint depositValue = 10_000;
        strate_push10000FromVaultgyInfo(depositValue);

        vm.prank(user3);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user3, address(0)));

        strategyWrapper.pull(depositValue);
    }

    function test_pull() external {
        uint depositValue = 10_000;
        strate_push10000FromVaultgyInfo(depositValue);

        uint balance = stackingMock.getBalance(address(strategyWrapper));
        uint balanceAndResullt = stackingMock.balanceAndResult(address(strategyWrapper));

        vm.assertEq(depositValue , balance);  

        vm.prank(address(vaultMock));
        strategyWrapper.pull(depositValue);

        uint calculatedProfit = stackingMock.calculateProfit(depositValue);

        vm.assertEq(balanceAndResullt - balance , calculatedProfit);  
    }

    function test_pause() external {
        vm.prank(address(vaultMock));
        strategyWrapper.pause();
    }

    function test_NotOwner_pause() external {
        vm.prank(user3);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user3, address(0)));
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
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user3, address(0)));
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
        uint check = strategyWrapper.lastTotalAssets();
        vm.assertEq(check, 0);

        uint newTotalAsset = 100_001;
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
    
    event Report(uint indexed time, uint256 indexed profit, uint256 indexed loss);

    event StrategyUnpaused(uint indexed timestamp);

    event StrategyPaused(uint indexed timestamp);

    function test_eventPull() external {
        uint depositValue = 10_000;
        strate_push10000FromVaultgyInfo(depositValue);

        vm.startPrank(address(vaultMock));
        (uint256 profit, uint loss) = strategyWrapper.report();
        
        vm.expectEmit(true, false, false, false);
        emit Pull(depositValue + profit - loss);

        strategyWrapper.pull(depositValue);
    }

    function test_eventPush() external {
        uint depositValue = 10_000;

        vm.startPrank(address(vaultMock));
        erc20Mock.approve(address(strategyWrapper), depositValue);
        
        vm.expectEmit(true, false, false, false);
        emit Push(depositValue);
        strategyWrapper.push(depositValue);
    }

    function test_eventReport() external {
        uint depositValue = 10_000;
        strate_push10000FromVaultgyInfo(depositValue);

        uint expercterProfit = stackingMock.calculateProfit(depositValue);
        uint expercterLoss = 0;

        vm.expectEmit(true, true, true, false);
        emit Report(block.timestamp, expercterProfit, expercterLoss);

        vm.prank(address(vaultMock));
        (uint256 profit, uint loss) = strategyWrapper.report();

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
