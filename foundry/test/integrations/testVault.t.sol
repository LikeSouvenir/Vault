// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Vault} from "../../src/Vault.sol";
import {BaseStrategy} from "../../src/BaseStrategy.sol";
import {CompoundUSDCStrategy} from "../../src/CompoundUSDCStrategy.sol";
import {AaveStrategy} from "../../src/AaveStrategy.sol";
import {IComet} from "../../src/interfaces/IComet.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Test, console, StdCheats} from "forge-std/Test.sol";
import {StdUtils} from "forge-std/StdUtils.sol";

uint16 constant DEFAULT_FEE = 100;
uint16 constant MAX_PERCENT = 10_000;
uint16 constant MIN_PERCENT = 1;

uint256 constant SECONDS_PER_YEAR = 31_556_952; // 365.2425 days
uint256 constant DEFAULT_USER_BALANCE = 10_000 ether;
uint16 constant STRATEGY_SHARE_PERCENT = 5_000; //50%
uint256 constant INVEST_VALUE_USDC = 1000e6;
uint256 constant INVEST_VALUE = 10 ether;
bytes32 constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

address constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
address constant COMET_USDC = 0xc3d688B66703497DAA19211EEdff47f25384cdc3;
address constant COMET_REWARDS = 0x1B0e765F6224C21223AeA2af16c1C46E38885a40;
IERC20 constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
IERC20 constant COMP = IERC20(0xc00e94Cb662C3520282E6f5717214004A7f26888);

address constant manager = 0x1C969b20A5985c02721FCa20c44F9bf8931856a8;
address constant feeRecipient = 0x8A969F0C98ff14c5fa92d75aadE3f329141a3384;

contract TestIntegVault is Test {
    Vault vault;
    CompoundUSDCStrategy compoundV3;
    AaveStrategy aave;

    address keeper = vm.addr(3);
    address user1 = vm.addr(4);
    address user2 = vm.addr(5);

    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        vault = new Vault(USDC, "vaultShare", "VS", manager, feeRecipient);

        require(address(COMET_USDC).code.length > 0, "Comet haven't code");
        require(IComet(COMET_USDC).balanceOf(address(this)) != type(uint256).max, "Comet unsupported WETH");

        compoundV3 = new CompoundUSDCStrategy(
            COMET_USDC,
            address(USDC),
            "compoundUSDCStrategy",
            address(vault),
            COMET_REWARDS,
            address(COMP),
            UNISWAP_V2_ROUTER
        );
        //         aave = new AaveStrategy(address(stackingMock), address(WETH), "aaveStrategy", address(vault));

        deal(address(COMP), user1, 100 ether);
        deal(address(COMP), user2, 100 ether);
        deal(address(USDC), user1, 10000e6);
        deal(address(USDC), user2, 10000e6);

        vm.startPrank(manager);
        vault.grantRole(KEEPER_ROLE, keeper);
        vault.add(compoundV3, STRATEGY_SHARE_PERCENT);
        // vault.add(aave, STRATEGY_SHARE_PERCENT);
        vm.stopPrank();
    }

    function _investUsdcFromUser(address user) internal returns (uint256 shares) {
        vm.startPrank(user);
        USDC.approve(address(vault), INVEST_VALUE_USDC);
        shares = vault.deposit(INVEST_VALUE_USDC, user);
        vm.stopPrank();

        assertEq(vault.balanceOf(user), shares);
    }

    function _rebalanceStrategy(BaseStrategy strategy) internal {
        uint256 vaultBalance = USDC.balanceOf(address(vault));

        vm.prank(keeper);
        vault.rebalance(strategy);

        uint256 strategyBalance = vault.strategyBalance(compoundV3);
        vm.assertEq(strategyBalance, vaultBalance * STRATEGY_SHARE_PERCENT / MAX_PERCENT, "strategy not enough tokens");
    }

    function _mintStrategy(BaseStrategy strategy, IERC20 token) internal {
        uint256 strategyBalance = token.balanceOf(address(strategy));
        deal(address(token), address(strategy), strategyBalance + 1000 * 1e18);
    }

    function testUniswapInteraction() public {
        _investUsdcFromUser(user1);
        _investUsdcFromUser(user2);

        uint256 balanceCompBefore = COMP.balanceOf(address(vault));
        uint256 balanceUsdcBefore = USDC.balanceOf(address(vault));

        _rebalanceStrategy(compoundV3);

        skip(10 days);
        _mintStrategy(compoundV3, COMP);

        vm.prank(keeper);
        vault.report(compoundV3);

        vm.prank(address(vault));
        compoundV3.harvest();

        uint256 balanceCompAfter = COMP.balanceOf(address(vault));
        uint256 balanceUsdcAfter = USDC.balanceOf(address(vault));

        vm.assertEq(balanceCompBefore, balanceCompAfter);
        vm.assertGt(balanceUsdcBefore, balanceUsdcAfter);
    }

    function testCompoundV3DefaultDepositWithdraw() public {
        _investUsdcFromUser(user1);
        _rebalanceStrategy(compoundV3);

        skip(30 days);
        _mintStrategy(compoundV3, COMP);

        vm.prank(keeper);
        vault.report(compoundV3);

        uint256 shares = vault.balanceOf(user1);
        vm.prank(user1);
        vault.redeem(shares, user1, user1);

        // check user profit
        uint256 finalBalance = USDC.balanceOf(user1);
        assertGt(finalBalance, INVEST_VALUE_USDC - 1, "profit less than invest amount");
    }

    // Тест миграции
    function testMigrateStrategy() public {
        _investUsdcFromUser(user1);
        _rebalanceStrategy(compoundV3);

        skip(1 days);
        vm.startPrank(manager);
        CompoundUSDCStrategy newCompoundV3 = new CompoundUSDCStrategy(
            COMET_USDC,
            address(USDC),
            "compoundUSDCStrategy",
            address(vault),
            COMET_REWARDS,
            address(COMP),
            UNISWAP_V2_ROUTER
        );

        vault.migrate(compoundV3, newCompoundV3);
        vm.stopPrank();

        assertEq(vault.strategyBalance(compoundV3), 0);
        assertGt(vault.strategyBalance(newCompoundV3), 0);
    }
}
