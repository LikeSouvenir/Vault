// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Vault/AssetERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
Затем пользователь наблюдает за ростом баланса, доступного для вывода из волта. В любой момент он
может передать свои share-токены обратно волту и получить то, что вложил, плюс накопленный 
доход (yield), если стратегия была успешной.

Синхронизировать доходы и убытки с волтом. 
 */

import {Slots} from "../Vault/utils/elements.sol";
import {IFeeConfig} from "./interfaces/IFeeConfig.sol";
import {BaseStrategy} from "./BaseStrategy.sol";
/**
 * синхронизация доходов
 * 
 */

contract Vault is ERC4626, IFeeConfig{
    uint constant BPS = 10_000;
    uint constant MAXIMUM_STRATEGIES = 20;

    uint16 _managementFee; // The percent in basis points of profit that is charged as a fee.
    address feeRecipient; // The address to pay the `performanceFee` to.

    address _management;
    address _keeper;

    mapping (BaseStrategy => uint) strategyBalancePersentMap;
    BaseStrategy[MAXIMUM_STRATEGIES] withdrawQueue;

    constructor() ERC4626(IERC20(new AssetERC20("Asset Token", "ASSET"))) ERC20("Share Token", "SHARE") {
         // string memory name_, string memory symbol_  
    }
//
    /**
     * @dev Require that the call is coming from the strategies management.
     */
    modifier onlyManagement() {
        require(msg.sender == _management, "management");
        _;
    }

    /**
     * @dev Require that the call is coming from either the strategies
     * management or the keeper.
     */
    modifier onlyKeeperOrManagement() {
        require(msg.sender == _keeper || msg.sender == _management, "keeper");
        _;
    }
//
    function straregySharePersent(BaseStrategy strategy) external view returns(uint) {
        return strategyBalancePersentMap[strategy];
    }

    function setSharePersent(BaseStrategy strategy, uint sharePersent) public onlyManagement {
        require(sharePersent > 0, "sharePersent must be > 0");

        uint currentPersent = strategyBalancePersentMap[strategy];
        uint totalSharePersent;
        
        for (uint i = 0; i < withdrawQueue.length; i++) {
            totalSharePersent += strategyBalancePersentMap[withdrawQueue[i]];
        }

        require(totalSharePersent - currentPersent + sharePersent >= 100, "total share > 100%");

        strategyBalancePersentMap[strategy] = sharePersent;
    }

    function reportsAndInvests() external onlyKeeperOrManagement {
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

    function rebalance(BaseStrategy strategy) public onlyKeeperOrManagement returns(uint maxAmount) {
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
    
    function migrate(BaseStrategy oldStrategy, BaseStrategy newStrategy) external onlyManagement {
        require (strategyBalancePersentMap[oldStrategy] != 0, "strategy not exist");

        for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
            if (withdrawQueue[i] == oldStrategy) {
                withdrawQueue[i] = newStrategy;

                oldStrategy.migrate(newStrategy);
            }
        }

        emit StrategyMigrated(address(oldStrategy), address(newStrategy));
    }

    function remove(BaseStrategy strategy) external onlyManagement returns(uint amountAssets){
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

    function add(BaseStrategy newStrategy, uint sharePersent) external onlyManagement {
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

    function setWithdrawalQueue(BaseStrategy[MAXIMUM_STRATEGIES] memory queue) external onlyManagement {
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

    function feeConfig() external view returns (uint16, address) {
        return (_managementFee, feeRecipient);
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

    function pause(BaseStrategy strategy) external onlyKeeperOrManagement {
        strategy.pause();
    }

    function unpause(BaseStrategy strategy) external onlyKeeperOrManagement {
        strategy.unpause();
    }

    event StrategyAdded (address indexed strategy, uint256 performanceFee);

    event UpdateStrategyBalance(BaseStrategy indexed strategy, uint newBalance);
    
    event UpdateWithdrawalQueue(BaseStrategy[MAXIMUM_STRATEGIES]);

    event StrategyMigrated ( address indexed oldVersion, address indexed newVersion );

    event StrategyRemoved ( address indexed strategy, uint totalAssets);
}