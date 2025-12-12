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

    mapping (BaseStrategy => uint) strategyBalancePersentMap;
    BaseStrategy[MAXIMUM_STRATEGIES] withdrawQueue;

    constructor(address manager) ERC4626(IERC20(new AssetERC20("Asset Token", "ASSET"))) ERC20("Share Token", "SHARE") {// string memory name_, string memory symbol_  
        _grantRole(DEFAULT_ADMIN_ROLE, manager);
    }
    
    function straregySharePersent(BaseStrategy strategy) external view returns(uint) {
        return strategyBalancePersentMap[strategy];
    }

    function setSharePersent(BaseStrategy strategy, uint sharePersent) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(sharePersent > 0, "sharePersent must be > 0");

        uint currentPersent = strategyBalancePersentMap[strategy];
        uint totalSharePersent;
        
        for (uint i = 0; i < withdrawQueue.length; i++) {
            totalSharePersent += strategyBalancePersentMap[withdrawQueue[i]];
        }

        require(totalSharePersent - currentPersent + sharePersent >= 100, "total share > 100%");

        strategyBalancePersentMap[strategy] = sharePersent;
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
        uint balancePersent = strategyBalancePersentMap[strategy];

        require(balancePersent != 0, "strategy not found");

        uint assetBalance = strategy.totalAssets();
        maxAmount = totalAssets() * balancePersent / 100;
        
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
        require (strategyBalancePersentMap[oldStrategy] != 0, "strategy not exist");

        for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
            if (withdrawQueue[i] == oldStrategy) {
                withdrawQueue[i] = newStrategy;

                oldStrategy.migrate(newStrategy);
            }
        }

        emit StrategyMigrated(address(oldStrategy), address(newStrategy));
    }

    function remove(BaseStrategy strategy) external onlyRole(DEFAULT_ADMIN_ROLE) returns(uint amountAssets){
        require (strategyBalancePersentMap[strategy] != 0, "strategy not exist");

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

    function add(BaseStrategy newStrategy, uint sharePersent) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require (strategyBalancePersentMap[newStrategy] == 0, "strategy exist");
        require (address(withdrawQueue[MAXIMUM_STRATEGIES - 1]) == address(0), "strategy count out of bounds");

        for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
            if (address(withdrawQueue[i]) == address(0)) {
                withdrawQueue[i] = newStrategy;
            }
        }

        setSharePersent(newStrategy, sharePersent);

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

            require(needed != 0, "not enaugth");
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

            require (strategyBalancePersentMap[queue[i]] != 0, "Incorrect address");
        }

        withdrawQueue = queue;

        emit UpdateWithdrawalQueue(queue);
    }

    function getWithdrabalQueue() external view returns(BaseStrategy[MAXIMUM_STRATEGIES] memory) {
        return withdrawQueue;
    }

    function strategyPesent(address strategy) external view returns(uint sharePersent) {
        return strategyBalancePersentMap[BaseStrategy(strategy)];
    }

    function setManagementFee(uint16 _fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_fee >= uint16(1), "min % is 0,01");
        _managementFee = _fee;
    }

    function setFeeRecipient(address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(recipient >= address(0), "zero address");
        _feeRecipient = recipient;
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
    }

    function unpause(BaseStrategy strategy) external onlyRole(KEEPER_ROLE) {
        strategy.unpause();
    }

    event StrategyAdded (address indexed strategy, uint256 performanceFee);

    event UpdateStrategyBalance(BaseStrategy indexed strategy, uint newBalance);
    
    event UpdateWithdrawalQueue(BaseStrategy[MAXIMUM_STRATEGIES]);

    event StrategyMigrated ( address indexed oldVersion, address indexed newVersion );

    event StrategyRemoved ( address indexed strategy, uint totalAssets);
}