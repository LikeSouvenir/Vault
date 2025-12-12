// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Vault/AssetERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


import {Slots} from "../Vault/utils/elements.sol";
import {IFeeConfig} from "./interfaces/IFeeConfig.sol";
import {BaseStrategy} from "./BaseStrategy.sol";
/**
все поля инициализированны
get $ set методы
events

Access Control
 */

contract Vault is ERC4626, AccessControl, IFeeConfig{
    uint constant BPS = 10_000;
    uint constant MAXIMUM_STRATEGIES = 20;

    uint16 _managementFee; // The percent in basis points of profit that is charged as a fee.
    address _feeRecipient; // The address to pay the `performanceFee` to.

    address _management;
    address _keeper;

    bytes32 constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    mapping (BaseStrategy => uint) strategyBalancePercentMap;
    BaseStrategy[MAXIMUM_STRATEGIES] withdrawQueue;

    constructor(address manager) ERC4626(IERC20(new AssetERC20("Asset Token", "ASSET"))) ERC20("Share Token", "SHARE") {// string memory name_, string memory symbol_  
        _grantRole(DEFAULT_ADMIN_ROLE, manager);
    }
    
    function strategySharePercent(BaseStrategy strategy) external view returns(uint) {
        return strategyBalancePercentMap[strategy];
    }

    function setSharePercent(BaseStrategy strategy, uint sharePercent) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(sharePercent > 0, "sharePercent must be > 0");

        uint currentPercent = strategyBalancePercentMap[strategy];
        uint totalSharePercent;
        
        for (uint i = 0; i < withdrawQueue.length; i++) {
            totalSharePercent += strategyBalancePercentMap[withdrawQueue[i]];
        }

        require(totalSharePercent - currentPercent + sharePercent <= 100, "total share <= 100%");

        strategyBalancePercentMap[strategy] = sharePercent;

        emit UpdateStrategySharePercent( address(strategy), sharePercent);
    }

    function reportsAndInvests() external onlyRole(KEEPER_ROLE) {
        uint len = withdrawQueue.length;

        for (uint i = 0; i < len; i++) {
            BaseStrategy strategy = withdrawQueue[i];

            strategy.report();
        }

        for (uint i = 0; i < len; i++) {
            BaseStrategy strategy = withdrawQueue[i];

            rebalance(strategy);
        }
    }

    function rebalance(BaseStrategy strategy) public onlyRole(KEEPER_ROLE) returns(uint maxAmount) {
        uint balancePercent = strategyBalancePercentMap[strategy];

        require(balancePercent != 0, "strategy not found");

        uint assetBalance = strategy.totalAssets();
        maxAmount = totalAssets() * balancePercent / 100;
        
        if (assetBalance < maxAmount) {
            IERC20(asset()).approve(address(strategy), maxAmount - assetBalance);

            strategy.deposit(maxAmount - assetBalance);

        } else if (assetBalance > maxAmount)  {
            IERC20(asset()).approve(address(strategy), assetBalance - maxAmount);

            strategy.withdraw(assetBalance - maxAmount);
        }

        emit UpdateStrategyBalance(strategy, maxAmount);
    }
    
    function migrate(BaseStrategy oldStrategy, BaseStrategy newStrategy) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require (strategyBalancePercentMap[oldStrategy] != 0, "strategy not exist");

        for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
            if (withdrawQueue[i] == oldStrategy) {
                withdrawQueue[i] = newStrategy;

                oldStrategy.migrate(newStrategy);
            }
        }

        emit StrategyMigrated(address(oldStrategy), address(newStrategy));
    }

    function remove(BaseStrategy strategy) external onlyRole(DEFAULT_ADMIN_ROLE) returns(uint amountAssets){
        require (strategyBalancePercentMap[strategy] != 0, "strategy not exist");

        bool find;
        for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
            if (withdrawQueue[i] == strategy) {
                amountAssets = strategy.emergencyWithdraw();
                find = true;
            }
            if (find && i != MAXIMUM_STRATEGIES - 1) {
                withdrawQueue[i] = withdrawQueue[i + 1];
            }
        }

        require(find, "strategy not removed");

        emit StrategyRemoved (address(strategy), amountAssets);
    }

    function add(BaseStrategy newStrategy, uint sharePercent) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require (strategyBalancePercentMap[newStrategy] == 0, "strategy exist");
        require (address(withdrawQueue[MAXIMUM_STRATEGIES - 1]) == address(0), "strategy count out of bounds");

        for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
            if (address(withdrawQueue[i]) == address(0)) {
                withdrawQueue[i] = newStrategy;
            }
        }

        setSharePercent(newStrategy, sharePercent);

        emit StrategyAdded(address(newStrategy), newStrategy.performanceFee());
    }

    function _withdraw( address caller, address receiver, address owner, uint256 assets, uint256 shares ) internal override {
        uint currentBalance = IERC20(asset()).balanceOf(address(this));
        if (currentBalance < assets){
            uint needed = assets - currentBalance;

            for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
                BaseStrategy currentStrategy = withdrawQueue[i];
                if (address(currentStrategy) == address(0)) {
                    break;
                }

                uint balance = currentStrategy.totalAssets();
                
                if (needed <= balance) {
                    currentStrategy.withdraw(needed);

                    needed = 0;
                    break;
                } else {
                    currentStrategy.withdraw(balance);
                    needed -= balance;
                }
            }

            require(needed == 0, "not enaugth");
        }

        super._withdraw(caller, receiver, owner, assets, shares);
    }


    function setWithdrawalQueue(BaseStrategy[MAXIMUM_STRATEGIES] memory queue) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
            BaseStrategy oldQueue = withdrawQueue[i];

            if (address(oldQueue) == address(0)) {
                break;
            }
            require (address(queue[i]) != address(0), "Cannot use to remove");

            require (strategyBalancePercentMap[queue[i]] != 0, "Incorrect address");
        }

        withdrawQueue = queue;

        emit UpdateWithdrawalQueue(queue);
    }

    function getWithdrabalQueue() external view returns(BaseStrategy[MAXIMUM_STRATEGIES] memory) {
        return withdrawQueue;
    }

    function strategyPesent(address strategy) external view returns(uint sharePercent) {
        return strategyBalancePercentMap[BaseStrategy(strategy)];
    }

    function setManagementFee(uint16 fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(fee >= uint16(1), "min % is 0,01");
        _managementFee = fee;

        emit UpdateManagementFee(fee);
    }

    function setFeeRecipient(address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(recipient >= address(0), "zero address");
        _feeRecipient = recipient;

        emit UpdateManagementRecipient(recipient);
    }

    function feeConfig() external view returns (uint16, address) {
        return (_managementFee, _feeRecipient);
    }

    function totalAssets() public view override returns (uint256) {
        uint256 vaultBalance = IERC20(asset()).balanceOf(address(this));

        for (uint256 i = 0; i < withdrawQueue.length; i++) {
            BaseStrategy strategy = withdrawQueue[i];

            vaultBalance += strategy.totalAssets();
        }

        return vaultBalance;
    }

    function strategyBalance(BaseStrategy strategy) public view returns(uint) {
        return strategy.totalAssets();
    }

    function pause(BaseStrategy strategy) external onlyRole(KEEPER_ROLE) {
        strategy.pause();

        emit StrategyPaused(address(strategy));
    }

    function unpause(BaseStrategy strategy) external onlyRole(KEEPER_ROLE) {
        strategy.unpause();

        emit StrategyUnpaused(address(strategy));
    }


    event StrategyUnpaused(address indexed strategy);

    event StrategyPaused(address indexed strategy);

    event UpdateManagementRecipient(address indexed recipient);
    
    event UpdateManagementFee(uint indexed fee);
    
    event UpdateStrategySharePercent(address indexed strategy, uint newPercent);

    event StrategyAdded (address indexed strategy, uint256 performanceFee);

    event UpdateStrategyBalance(BaseStrategy indexed strategy, uint newBalance);
    
    event UpdateWithdrawalQueue(BaseStrategy[MAXIMUM_STRATEGIES]);

    event StrategyMigrated ( address indexed oldVersion, address indexed newVersion );

    event StrategyRemoved ( address indexed strategy, uint totalAssets);
}