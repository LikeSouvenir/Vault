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

    uint _totalAssets;

    mapping (BaseStrategy => uint shares) strategiesSharesMap;
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

    function strategyBalance(BaseStrategy strategy) public view returns(uint) {
        return strategy.totalAssets();
    }

    function pause(BaseStrategy strategy) external onlyKeeperOrManagement {
        strategy.pause();
    }

    function unpause(BaseStrategy strategy) external onlyKeeperOrManagement {
        strategy.unpause();
    }

    event StrategyMigrated ( address indexed oldVersion, address indexed newVersion );
    
    function migrate(BaseStrategy oldStrategy, BaseStrategy newStrategy) external onlyManagement {
        require (strategiesSharesMap[oldStrategy] != 0, "strategy not exist");

        for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
            if (withdrawQueue[i] == oldStrategy) {
                withdrawQueue[i] = newStrategy;

                oldStrategy.migrate(newStrategy);
            }
        }

        emit StrategyMigrated(address(oldStrategy), address(newStrategy));
    }

    event StrategyRemoved ( address indexed strategy, uint totalAssets);

    function remove(BaseStrategy strategy) external onlyManagement returns(uint amountAssets){
        require (strategiesSharesMap[strategy] != 0, "strategy not exist");

        bool find;
        for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
            if (withdrawQueue[i] == strategy) {
                amountAssets = strategy.emergencyWithdraw();
                find = true;
            }
            if (find && MAXIMUM_STRATEGIES != MAXIMUM_STRATEGIES - 1) {
                withdrawQueue[i] = withdrawQueue[i + 1];
            }
        }

        require(find, "strategy not removed");

        emit StrategyRemoved (address(strategy), amountAssets);
    }

    event StrategyAdded (address indexed strategy, uint256 performanceFee);

    function add(BaseStrategy newStrategy, uint sharePersent) external onlyManagement {
        require (strategiesSharesMap[newStrategy] == 0, "strategy exist");
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
            uint amount = currentBalance - assets;

            for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
                BaseStrategy currentStrategy = withdrawQueue[i];
                if (address(currentStrategy) == address(0)) {
                    break;
                }

                uint strategyBalance = currentStrategy.totalAssets();
                
                if (amount <= strategyBalance) {
                    currentStrategy.withdraw(amount);
                    break;
                } else {
                    currentStrategy.withdraw(strategyBalance);
                    amount -= strategyBalance;
                }
            }

            require(amount > 0, "not enaught");
        }

        super._withdraw(caller, receiver, owner, assets, shares);
    }
    
    event UpdateWithdrawalQueue(BaseStrategy[MAXIMUM_STRATEGIES]);

    function setWithdrawalQueue(BaseStrategy[MAXIMUM_STRATEGIES] memory queue) external onlyManagement {
        for (uint i = 0; i < MAXIMUM_STRATEGIES; i++) {
            BaseStrategy oldQueue = withdrawQueue[i];

            if (address(oldQueue) == address(0)) {
                break;
            }
            require (address(queue[i]) != address(0), "Cannot use to remove");

            require (strategiesSharesMap[queue[i]] == 0, "Incorrect address");
        }

        withdrawQueue = queue;

        emit UpdateWithdrawalQueue(queue);
    }

    function getWithdrabalQueue() external view returns(BaseStrategy[MAXIMUM_STRATEGIES] memory) {
        return withdrawQueue;
    }

    function reportAndInvest(BaseStrategy strategy) external onlyKeeperOrManagement {
        /* (uint256 profit, uint256 loss) = */ strategy.report();

        updateStrategyBalance(strategy);
    }

    event UpdateStrategyBalance(BaseStrategy indexed strategy, uint newBalance);

    function updateStrategyBalance(BaseStrategy strategy) public onlyKeeperOrManagement returns(uint maxAmount) {
        uint sharePersent = strategiesSharesMap[strategy];

        require(sharePersent != 0, "strategy not found");

        uint currentBalance = strategy.totalAssets();
        maxAmount = _totalAssets * sharePersent / 100;
        
        if (currentBalance < maxAmount) {
            strategy.deposit(maxAmount - currentBalance);

        } else if (currentBalance > maxAmount)  {
            strategy.withdraw(currentBalance - maxAmount);
        }

        emit UpdateStrategyBalance(strategy, maxAmount);
    }

    function setSharePersent(BaseStrategy strategy, uint sharePersent) public onlyManagement {
        require(sharePersent > 0, "sharePersent must be > 0");
        require(sharePersent <= 100, "sharePersent must be <= 100");

        strategiesSharesMap[strategy] = sharePersent;
    }

    function strategyPesent(address strategy) external view returns(uint sharePersent) {
        return strategiesSharesMap[BaseStrategy(strategy)];
    }

    function feeConfig() external view returns (uint16, address) {
        return (_managementFee, feeRecipient);
    }

    function totalAssets() public view override returns (uint256) {
        return _totalAssets;
    }
}