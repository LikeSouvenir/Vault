# Отчеты

**Данный отчет касаеться исключительно основного контракта `Vault.sol` и `BaseStrategy` ввиде `WrapperBaseStrategy.sol`**

## SybGraph public link
https://api.goldsky.com/api/public/project_cmkbf9ivc8p0x01xd7xjq8u56/subgraphs/vault-with-base-strategy/1.0.1/gn

## Test
#### Ran 33 tests for BaseStrategyWrapper
```
[PASS] test_Constructor_ZeroAssetToken() (gas: 67693)
[PASS] test_Constructor_ZeroVault() (gas: 67733)
[PASS] test_NotOwner_pause() (gas: 14658)
[PASS] test_NotOwner_unpause() (gas: 53175)
[PASS] test_NotVault_emergencyWithdraw() (gas: 14933)
[PASS] test_NotVault_pull() (gas: 175685)
[PASS] test_NotVault_push() (gas: 46068)
[PASS] test_NotVault_takeAndClose() (gas: 14846)
[PASS] test_RebalanceAndReport_NotKeeper() (gas: 16154)
[PASS] test_RebalanceAndReport_Success() (gas: 201084)
[PASS] test_WhenPaused_pause() (gas: 57765)
[PASS] test_asset() (gas: 11215)
[PASS] test_emergencyWithdraw_WhenEmpty() (gas: 46166)
[PASS] test_emergencyWithdraw_WithBalance() (gas: 215813)
[PASS] test_eventPause() (gas: 47717)
[PASS] test_eventPull() (gas: 217404)
[PASS] test_eventPush() (gas: 149380)
[PASS] test_eventReport() (gas: 205411)
[PASS] test_eventUnpause() (gas: 65494)
[PASS] test_isPaused() (gas: 49274)
[PASS] test_lastTotalAssets() (gas: 150622)
[PASS] test_name() (gas: 12911)
[PASS] test_pause() (gas: 45756)
[PASS] test_pull() (gas: 233040)
[PASS] test_pull_InsufficientAssets() (gas: 174865)
[PASS] test_push() (gas: 176314)
[PASS] test_report() (gas: 390600)
[PASS] test_report_WithLoss() (gas: 235764)
[PASS] test_report_ZeroProfitZeroLoss() (gas: 182624)
[PASS] test_supportsInterface() (gas: 9444)
[PASS] test_takeAndClose() (gas: 214120)
[PASS] test_unpause() (gas: 63469)
[PASS] test_vault() (gas: 11248)
```
Suite result: ok. 33 passed; 0 failed; 0 skipped; finished in 7.79ms (16.28ms CPU time)

#### Ran 61 tests for Vault
```
    [PASS] test_add() (gas: 108929)
    [PASS] test_constructorZeroAddresses() (gas: 348484)
    [PASS] test_feeRecipient() (gas: 13437)
    [PASS] test_managementFee() (gas: 11269)
    [PASS] test_maxRedeem() (gas: 233799)
    [PASS] test_maxWithdraw() (gas: 233886)
    [PASS] test_migrate() (gas: 305550)
    [PASS] test_more100PercentFeeSetManagementFee() (gas: 111711)
    [PASS] test_more100PercentFeeSetPerformanceFee() (gas: 112487)
    [PASS] test_notAdminStrategyGrantRole() (gas: 119353)
    [PASS] test_notExistsRemove() (gas: 19553)
    [PASS] test_otherVaultInAdd() (gas: 7100369)
    [PASS] test_outOfBoundsLimitedAdd() (gas: 33968995)
    [PASS] test_pause() (gas: 184766)
    [PASS] test_performanceFee() (gas: 111979)
    [PASS] test_rebalance() (gas: 508479)
    [PASS] test_rebalanceWithdrawExcess() (gas: 422064)
    [PASS] test_redeem() (gas: 440427)
    [PASS] test_redeemWithMultipleStrategies() (gas: 660064)
    [PASS] test_remove() (gas: 196222)
    [PASS] test_reportFeeExceedsProfit() (gas: 446790)
    [PASS] test_reportWhenLossExceedsBalance() (gas: 392788)
    [PASS] test_reportWhenLossGreaterThanBalance() (gas: 362566)
    [PASS] test_sameStrategyAdd() (gas: 118701)
    [PASS] test_setFeeRecipient() (gas: 119755)
    [PASS] test_setManagementFee() (gas: 118917)
    [PASS] test_setPerformanceFee() (gas: 116431)
    [PASS] test_setSharePercent() (gas: 118234)
    [PASS] test_setSharePercentExceeds100Percent() (gas: 207124)
    [PASS] test_setWithdrawalQueue() (gas: 322709)
    [PASS] test_setWithdrawalQueueWithZeroAddress() (gas: 128746)
    [PASS] test_strategyBalance() (gas: 351685)
    [PASS] test_strategyGrantRole() (gas: 145965)
    [PASS] test_strategyGrantRoleSelf() (gas: 112767)
    [PASS] test_strategyRevokeRole() (gas: 134122)
    [PASS] test_strategyRevokeRoleSelf() (gas: 112789)
    [PASS] test_strategySharePercent() (gas: 351941)
    [PASS] test_supportsInterface() (gas: 21585)
    [PASS] test_totalAssets() (gas: 229316)
    [PASS] test_totalAssetsWithPausedStrategy() (gas: 395651)
    [PASS] test_unpause() (gas: 201264)
    [PASS] test_unsuitableTokenAdd() (gas: 2435249)
    [PASS] test_whenNotPausedEmergencyWithdraw() (gas: 462700)
    [PASS] test_whenPausedEmergencyWithdraw() (gas: 470350)
    [PASS] test_withChangeStrategySetWithdrawalQueue() (gas: 1830967)
    [PASS] test_withLossReport() (gas: 399324)
    [PASS] test_withManagementFeeReport() (gas: 450371)
    [PASS] test_withProfitReport() (gas: 437805)
    [PASS] test_withdraw() (gas: 442845)
    [PASS] test_withdrawFromMultipleStrategies() (gas: 698340)
    [PASS] test_withdrawMoreThanVaultBalance() (gas: 434572)
    [PASS] test_withdrawSkipZeroBalanceStrategy() (gas: 508438)
    [PASS] test_withdrawWithEmptyQueue() (gas: 130173)
    [PASS] test_withdrawWithEmptyStrategyInQueue() (gas: 508060)
    [PASS] test_withdrawWithoutStrategyBalance() (gas: 220687)
    [PASS] test_withdrawalQueue() (gas: 165649)
    [PASS] test_withoutAllowanceAdd() (gas: 32788)
    [PASS] test_withoutRolesAdd() (gas: 18813)
    [PASS] test_zeroAddressSetFeeRecipient() (gas: 111738)
    [PASS] test_zeroFeeSetManagementFee() (gas: 111694)
    [PASS] test_zeroFeeSetPerformanceFee() (gas: 112428)
```
Suite result: ok. 61 passed; 0 failed; 0 skipped; finished in 10.29ms (27.93ms CPU time)

Ran 2 test suites in 22.70ms (18.08ms CPU time): 94 tests passed, 0 failed, 0 skipped (94 total tests)

#### Ran 4 fork tests for Vault & BaseStrategy
```
[PASS] testCompoundV3DefaultDepositWithdraw() (gas: 788076)
[PASS] testMigrateStrategy() (gas: 2232254)
[PASS] testRebalanceAndReport() (gas: 752056)
[PASS] testUniswapInteraction() (gas: 765628)
```
Suite result: ok. 4 passed; 0 failed; 0 skipped; finished in 19.52s (27.44s CPU time)

Ran 1 test suite in 24.76s (19.52s CPU time): 4 tests passed, 0 failed, 0 skipped (4 total tests)
## Coverage

**Current view:** top level - src/src  
**Test:** lcov.info  
**Test Date:** 2026-01-19 20:16:18

### Summary

| Metric      | Coverage | Total | Hit |
|-------------|----------|-------|-----|
| **Lines**     | 100.0%   | 280   | 280 |
| **Functions** | 100.0%   | 57    | 57  |
| **Branches**  | 93.5%    | 77    | 72  |

### File Details

| Filenam e            | Line Coverage| <--     | <--  | Branch Coverage | <--     | <--  | Function Coverage| <--     | <--  |
|----------------------|--------------|--------|-----|-----------------|--------|-----|------------------|--------|-----|
|                      | Rate         | Total  | Hit | Rate            | Total  | Hit | Rate             | Total  | Hit |
| **BaseStrategy.sol** | 100.0%       | 100.0% | 64  | 64              | 100.0% | 10  | 10               | 100.0% | 16  |
| **Vault.sol**        | 100.0%       | 100.0% | 216 | 216             | 92.5%  | 67  | 62               | 100.0% | 41  |

*Generated by: LCOV version 2.0-1*

---
## Slither
**THIS CHECKLIST IS NOT COMPLETE**. Use `--show-ignored-findings` to show all the results.
Summary
- [calls-loop](#calls-loop) (24 results) (Low)
- [reentrancy-benign](#reentrancy-benign) (2 results) (Low)
- [reentrancy-events](#reentrancy-events) (6 results) (Low)
- [timestamp](#timestamp) (6 results) (Low)
- [solc-version](#solc-version) (1 results) (Informational)
- [naming-convention](#naming-convention) (1 results) (Informational)

## calls-loop
Impact: Low
Confidence: Medium
- [ ] ID-4
  [Vault.totalAssets()](src/Vault.sol#L696-L713) has external calls inside a loop: [strategy.isPaused()](src/Vault.sol#L705)
  Calls stack containing the loop:
  ERC4626.deposit(uint256,address)
  ERC4626.previewDeposit(uint256)
  ERC4626._convertToShares(uint256,Math.Rounding)

src/Vault.sol#L696-L713


- [ ] ID-5
  [Vault.migrate(IBaseStrategy,IBaseStrategy)](src/Vault.sol#L248-L283) has external calls inside a loop: [balance = oldStrategy.pull(info.balance + profit)](src/Vault.sol#L274)

src/Vault.sol#L248-L283


- [ ] ID-6
  [Vault.migrate(IBaseStrategy,IBaseStrategy)](src/Vault.sol#L248-L283) has external calls inside a loop: [newStrategy.push(balance)](src/Vault.sol#L277)

src/Vault.sol#L248-L283


- [ ] ID-7
  [Vault.totalAssets()](src/Vault.sol#L696-L713) has external calls inside a loop: [strategy.isPaused()](src/Vault.sol#L705)
  Calls stack containing the loop:
  Vault.redeem(uint256,address,address)
  ERC4626.redeem(uint256,address,address)
  Vault.maxRedeem(address)

src/Vault.sol#L696-L713


- [ ] ID-8
  [Vault.totalAssets()](src/Vault.sol#L696-L713) has external calls inside a loop: [strategy.isPaused()](src/Vault.sol#L705)
  Calls stack containing the loop:
  Vault.maxWithdraw(address)

src/Vault.sol#L696-L713


- [ ] ID-9
  [Vault.totalAssets()](src/Vault.sol#L696-L713) has external calls inside a loop: [strategy.isPaused()](src/Vault.sol#L705)

src/Vault.sol#L696-L713


- [ ] ID-10
  [Vault.totalAssets()](src/Vault.sol#L696-L713) has external calls inside a loop: [strategy.isPaused()](src/Vault.sol#L705)
  Calls stack containing the loop:
  ERC4626.convertToShares(uint256)
  ERC4626._convertToShares(uint256,Math.Rounding)

src/Vault.sol#L696-L713


- [ ] ID-11
  [Vault._withdraw(address,address,address,uint256,uint256)](src/Vault.sol#L319-L347) has external calls inside a loop: [info.balance -= strategy.pull(take)](src/Vault.sol#L337)
  Calls stack containing the loop:
  Vault.withdraw(uint256,address,address)
  ERC4626.withdraw(uint256,address,address)

src/Vault.sol#L319-L347


- [ ] ID-12
  [Vault.totalAssets()](src/Vault.sol#L696-L713) has external calls inside a loop: [strategy.isPaused()](src/Vault.sol#L705)
  Calls stack containing the loop:
  Vault.withdraw(uint256,address,address)
  ERC4626.withdraw(uint256,address,address)
  Vault.maxWithdraw(address)

src/Vault.sol#L696-L713


- [ ] ID-13
  [Vault.totalAssets()](src/Vault.sol#L696-L713) has external calls inside a loop: [strategy.isPaused()](src/Vault.sol#L705)
  Calls stack containing the loop:
  ERC4626.previewMint(uint256)
  ERC4626._convertToAssets(uint256,Math.Rounding)

src/Vault.sol#L696-L713


- [ ] ID-14
  [Vault._report(IBaseStrategy,bool)](src/Vault.sol#L367-L413) has external calls inside a loop: [(profit,loss) = strategy.report()](src/Vault.sol#L372)
  Calls stack containing the loop:
  Vault.migrate(IBaseStrategy,IBaseStrategy)

src/Vault.sol#L367-L413


- [ ] ID-15
  [Vault.totalAssets()](src/Vault.sol#L696-L713) has external calls inside a loop: [vaultBalance = IERC20(asset()).balanceOf(address(this))](src/Vault.sol#L697)
  Calls stack containing the loop:
  Vault.migrate(IBaseStrategy,IBaseStrategy)
  Vault._report(IBaseStrategy,bool)
  ERC4626.previewDeposit(uint256)
  ERC4626._convertToShares(uint256,Math.Rounding)

src/Vault.sol#L696-L713


- [ ] ID-16
  [Vault.totalAssets()](src/Vault.sol#L696-L713) has external calls inside a loop: [strategy.isPaused()](src/Vault.sol#L705)
  Calls stack containing the loop:
  ERC4626.convertToAssets(uint256)
  ERC4626._convertToAssets(uint256,Math.Rounding)

src/Vault.sol#L696-L713


- [ ] ID-17
  [Vault.totalAssets()](src/Vault.sol#L696-L713) has external calls inside a loop: [strategy.isPaused()](src/Vault.sol#L705)
  Calls stack containing the loop:
  Vault.report(IBaseStrategy)
  Vault._report(IBaseStrategy,bool)
  ERC4626.previewDeposit(uint256)
  ERC4626._convertToShares(uint256,Math.Rounding)

src/Vault.sol#L696-L713


- [ ] ID-18
  [Vault.migrate(IBaseStrategy,IBaseStrategy)](src/Vault.sol#L248-L283) has external calls inside a loop: [balance = oldStrategy.pull(info.balance - loss)](src/Vault.sol#L274)

src/Vault.sol#L248-L283


- [ ] ID-19
  [Vault.totalAssets()](src/Vault.sol#L696-L713) has external calls inside a loop: [strategy.isPaused()](src/Vault.sol#L705)
  Calls stack containing the loop:
  Vault.rebalance(IBaseStrategy)
  Vault._rebalance(IBaseStrategy)

src/Vault.sol#L696-L713


- [ ] ID-20
  [Vault.totalAssets()](src/Vault.sol#L696-L713) has external calls inside a loop: [strategy.isPaused()](src/Vault.sol#L705)
  Calls stack containing the loop:
  Vault.maxRedeem(address)

src/Vault.sol#L696-L713


- [ ] ID-21
  [Vault.totalAssets()](src/Vault.sol#L696-L713) has external calls inside a loop: [strategy.isPaused()](src/Vault.sol#L705)
  Calls stack containing the loop:
  Vault.migrate(IBaseStrategy,IBaseStrategy)
  Vault._report(IBaseStrategy,bool)
  ERC4626.previewDeposit(uint256)
  ERC4626._convertToShares(uint256,Math.Rounding)

src/Vault.sol#L696-L713


- [ ] ID-22
  [Vault.totalAssets()](src/Vault.sol#L696-L713) has external calls inside a loop: [strategy.isPaused()](src/Vault.sol#L705)
  Calls stack containing the loop:
  ERC4626.previewWithdraw(uint256)
  ERC4626._convertToShares(uint256,Math.Rounding)

src/Vault.sol#L696-L713


- [ ] ID-23
  [Vault._notPaused(IBaseStrategy)](src/Vault.sol#L190-L192) has external calls inside a loop: [require(bool,string)(! strategy.isPaused(),is paused)](src/Vault.sol#L191)
  Calls stack containing the loop:
  Vault.migrate(IBaseStrategy,IBaseStrategy)
  Vault._report(IBaseStrategy,bool)
  Vault.notPaused(IBaseStrategy)

src/Vault.sol#L190-L192


- [ ] ID-24
  [Vault.totalAssets()](src/Vault.sol#L696-L713) has external calls inside a loop: [strategy.isPaused()](src/Vault.sol#L705)
  Calls stack containing the loop:
  ERC4626.previewRedeem(uint256)
  ERC4626._convertToAssets(uint256,Math.Rounding)

src/Vault.sol#L696-L713


- [ ] ID-25
  [Vault.totalAssets()](src/Vault.sol#L696-L713) has external calls inside a loop: [strategy.isPaused()](src/Vault.sol#L705)
  Calls stack containing the loop:
  ERC4626.mint(uint256,address)
  ERC4626.previewMint(uint256)
  ERC4626._convertToAssets(uint256,Math.Rounding)

src/Vault.sol#L696-L713


- [ ] ID-26
  [Vault._withdraw(address,address,address,uint256,uint256)](src/Vault.sol#L319-L347) has external calls inside a loop: [info.balance -= strategy.pull(take)](src/Vault.sol#L337)
  Calls stack containing the loop:
  Vault.redeem(uint256,address,address)
  ERC4626.redeem(uint256,address,address)

src/Vault.sol#L319-L347


- [ ] ID-27
  [Vault.totalAssets()](src/Vault.sol#L696-L713) has external calls inside a loop: [strategy.isPaused()](src/Vault.sol#L705)
  Calls stack containing the loop:
  ERC4626.previewDeposit(uint256)
  ERC4626._convertToShares(uint256,Math.Rounding)

src/Vault.sol#L696-L713


## reentrancy-benign
Impact: Low
Confidence: Medium
- [ ] ID-28
  Reentrancy in [Vault._report(IBaseStrategy,bool)](src/Vault.sol#L367-L413):
  External calls:
    - [(profit,loss) = strategy.report()](src/Vault.sol#L372)
      State variables written after the call(s):
    - [_mint(_feeRecipient,previewDeposit(currentFee))](src/Vault.sol#L407)
        - [_balances[from] = fromBalance - value](lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L199)
        - [_balances[to] += value](lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L211)
    - [info.balance = 0](src/Vault.sol#L379)
    - [info.balance -= loss](src/Vault.sol#L381)
    - [info.balance += profit](src/Vault.sol#L387)
    - [info.lastTakeTime = uint96(block.timestamp)](src/Vault.sol#L396)
    - [_mint(_feeRecipient,previewDeposit(currentFee))](src/Vault.sol#L407)
        - [_totalSupply += value](lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L191)
        - [_totalSupply -= value](lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L206)

src/Vault.sol#L367-L413


- [ ] ID-29
  Reentrancy in [BaseStrategy.push(uint256)](src/BaseStrategy.sol#L103-L110):
  External calls:
    - [SafeERC20.safeTransferFrom(_asset,msg.sender,address(this),amount)](src/BaseStrategy.sol#L104)
      State variables written after the call(s):
    - [_lastTotalAssets += amount](src/BaseStrategy.sol#L107)

src/BaseStrategy.sol#L103-L110


## reentrancy-events
Impact: Low
Confidence: Medium
- [ ] ID-30
  Reentrancy in [Vault._report(IBaseStrategy,bool)](src/Vault.sol#L367-L413):
  External calls:
    - [(profit,loss) = strategy.report()](src/Vault.sol#L372)
      Event emitted after the call(s):
    - [Reported(profit,loss,currentManagementFee,currentPerformanceFee)](src/Vault.sol#L412)
    - [Transfer(from,to,value)](lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L215)
        - [_mint(_feeRecipient,previewDeposit(currentFee))](src/Vault.sol#L407)

src/Vault.sol#L367-L413


- [ ] ID-31
  Reentrancy in [Vault._rebalance(IBaseStrategy)](src/Vault.sol#L431-L452):
  External calls:
    - [IERC20(asset()).forceApprove(address(strategy),toDeposit)](src/Vault.sol#L443)
    - [strategy.push(toDeposit)](src/Vault.sol#L444)
    - [info.balance -= strategy.pull(toWithdraw)](src/Vault.sol#L448)
      Event emitted after the call(s):
    - [UpdateStrategyInfo(strategy,amount)](src/Vault.sol#L451)

src/Vault.sol#L431-L452


- [ ] ID-32
  Reentrancy in [Vault.migrate(IBaseStrategy,IBaseStrategy)](src/Vault.sol#L248-L283):
  External calls:
    - [(profit,loss,None) = _report(oldStrategy,false)](src/Vault.sol#L272)
        - [(profit,loss) = strategy.report()](src/Vault.sol#L372)
    - [IERC20(asset()).forceApprove(address(newStrategy),balance)](src/Vault.sol#L276)
    - [newStrategy.push(balance)](src/Vault.sol#L277)
    - [balance = oldStrategy.pull(info.balance + profit)](src/Vault.sol#L274)
    - [balance = oldStrategy.pull(info.balance - loss)](src/Vault.sol#L274)
      Event emitted after the call(s):
    - [StrategyMigrated(address(oldStrategy),address(newStrategy))](src/Vault.sol#L282)

src/Vault.sol#L248-L283


- [ ] ID-33
  Reentrancy in [Vault._withdraw(address,address,address,uint256,uint256)](src/Vault.sol#L319-L347):
  External calls:
    - [info.balance -= strategy.pull(take)](src/Vault.sol#L337)
    - [super._withdraw(caller,receiver,owner,assets,shares)](src/Vault.sol#L346)
        - [returndata = address(token).functionCall(data)](lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L96)
        - [SafeERC20.safeTransfer(_asset,receiver,assets)](lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol#L278)
        - [(success,returndata) = target.call{value: value}(data)](lib/openzeppelin-contracts/contracts/utils/Address.sol#L87)
          External calls sending eth:
    - [super._withdraw(caller,receiver,owner,assets,shares)](src/Vault.sol#L346)
        - [(success,returndata) = target.call{value: value}(data)](lib/openzeppelin-contracts/contracts/utils/Address.sol#L87)
          Event emitted after the call(s):
    - [Approval(owner,spender,value)](lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L293)
        - [super._withdraw(caller,receiver,owner,assets,shares)](src/Vault.sol#L346)
    - [Transfer(from,to,value)](lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L215)
        - [super._withdraw(caller,receiver,owner,assets,shares)](src/Vault.sol#L346)
    - [Withdraw(caller,receiver,owner,assets,shares)](lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol#L280)
        - [super._withdraw(caller,receiver,owner,assets,shares)](src/Vault.sol#L346)

src/Vault.sol#L319-L347


- [ ] ID-34
  Reentrancy in [Vault.remove(IBaseStrategy)](src/Vault.sol#L461-L482):
  External calls:
    - [amountAssets = strategy.takeAndClose()](src/Vault.sol#L479)
      Event emitted after the call(s):
    - [StrategyRemoved(address(strategy),amountAssets)](src/Vault.sol#L481)

src/Vault.sol#L461-L482


- [ ] ID-35
  Reentrancy in [BaseStrategy.emergencyWithdraw()](src/BaseStrategy.sol#L170-L174):
  External calls:
    - [amount = _emergencyWithdraw()](src/BaseStrategy.sol#L171)
        - [returndata = address(token).functionCall(data)](lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L96)
        - [(success,returndata) = target.call{value: value}(data)](lib/openzeppelin-contracts/contracts/utils/Address.sol#L87)
        - [SafeERC20.safeTransfer(IERC20(_asset),address(_vault),amount)](src/BaseStrategy.sol#L186)
          External calls sending eth:
    - [amount = _emergencyWithdraw()](src/BaseStrategy.sol#L171)
        - [(success,returndata) = target.call{value: value}(data)](lib/openzeppelin-contracts/contracts/utils/Address.sol#L87)
          Event emitted after the call(s):
    - [EmergencyWithdraw(block.timestamp,amount)](src/BaseStrategy.sol#L173)

src/BaseStrategy.sol#L170-L174


## timestamp
Impact: Low
Confidence: Medium
- [ ] ID-36
  [Vault.migrate(IBaseStrategy,IBaseStrategy)](src/Vault.sol#L248-L283) uses timestamp for comparisons
  Dangerous comparisons:
    - [require(bool,string)(_strategyInfoMap[newStrategy].sharePercent == 0,strategy already exist)](src/Vault.sol#L255)

src/Vault.sol#L248-L283


- [ ] ID-37
  [Vault.setWithdrawalQueue(IBaseStrategy[20])](src/Vault.sol#L491-L506) uses timestamp for comparisons
  Dangerous comparisons:
    - [require(bool,string)(_strategyInfoMap[newPos].sharePercent > 0,Cannot use to change strategies)](src/Vault.sol#L500)

src/Vault.sol#L491-L506


- [ ] ID-38
  [Vault.remove(IBaseStrategy)](src/Vault.sol#L461-L482) uses timestamp for comparisons
  Dangerous comparisons:
    - [require(bool,string)(_strategyInfoMap[strategy].sharePercent > 0,strategy not exist)](src/Vault.sol#L462)

src/Vault.sol#L461-L482


- [ ] ID-39
  [Vault._report(IBaseStrategy,bool)](src/Vault.sol#L367-L413) uses timestamp for comparisons
  Dangerous comparisons:
    - [currentFee > 0](src/Vault.sol#L403)
    - [profit < currentFee](src/Vault.sol#L404)

src/Vault.sol#L367-L413


- [ ] ID-40
  [Vault.add(IBaseStrategy,uint16)](src/Vault.sol#L206-L236) uses timestamp for comparisons
  Dangerous comparisons:
    - [require(bool,string)(info.sharePercent == 0,strategy exist)](src/Vault.sol#L221)

src/Vault.sol#L206-L236


- [ ] ID-41
  [Vault._rebalance(IBaseStrategy)](src/Vault.sol#L431-L452) uses timestamp for comparisons
  Dangerous comparisons:
    - [require(bool,string)(info.sharePercent > 0,strategy not found)](src/Vault.sol#L434)

src/Vault.sol#L431-L452


## solc-version
Impact: Informational
Confidence: High
- [ ] ID-42
  Version constraint ^0.8.20 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
    - VerbatimInvalidDeduplication
    - FullInlinerNonExpressionSplitArgumentEvaluationOrder
    - MissingSideEffectsOnSelectorAccess.
      It is used by:
    - [^0.8.20](lib/openzeppelin-contracts/contracts/access/AccessControl.sol#L4)
    - [^0.8.20](lib/openzeppelin-contracts/contracts/access/IAccessControl.sol#L4)
    - [^0.8.20](lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol#L4)
    - [^0.8.20](lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol#L4)
    - [^0.8.20](lib/openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol#L4)
    - [^0.8.20](lib/openzeppelin-contracts/contracts/interfaces/IERC4626.sol#L4)
    - [^0.8.20](lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol#L3)
    - [^0.8.20](lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L4)
    - [^0.8.20](lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol#L4)
    - [^0.8.20](lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol#L4)
    - [^0.8.20](lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol#L4)
    - [^0.8.20](lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol#L4)
    - [^0.8.20](lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L4)
    - [^0.8.20](lib/openzeppelin-contracts/contracts/utils/Address.sol#L4)
    - [^0.8.20](lib/openzeppelin-contracts/contracts/utils/Context.sol#L4)
    - [^0.8.20](lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol#L4)
    - [^0.8.20](lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol#L4)
    - [^0.8.20](lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol#L4)
    - [^0.8.20](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L4)
    - [^0.8.20](src/BaseStrategy.sol#L2)
    - [^0.8.20](src/StrategyExamples/AaveUsdcStrategy.sol#L2)
    - [^0.8.20](src/StrategyExamples/CompoundUsdcStrategy.sol#L2)
    - [^0.8.20](src/Vault.sol#L3)
    - [^0.8.20](src/interfaces/IAaveV3.sol#L2)
    - [^0.8.20](src/interfaces/IBaseStrategy.sol#L2)
    - [^0.8.20](src/interfaces/IComet.sol#L2)
    - [^0.8.20](src/interfaces/IUniswapV2Router.sol#L2)
    - [^0.8.20](src/interfaces/IVault.sol#L2)

lib/openzeppelin-contracts/contracts/access/AccessControl.sol#L4


## naming-convention
Impact: Informational
Confidence: High
- [ ] ID-43
  Function [IAToken.UNDERLYING_ASSET_ADDRESS()](src/interfaces/IAaveV3.sol#L74) is not in mixedCase

src/interfaces/IAaveV3.sol#L74