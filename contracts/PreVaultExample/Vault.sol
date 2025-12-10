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
 * синхронизация доходов
 * 
 */

contract Vault is ERC4626, IFeeConfig{
    uint constant BPS = 10_000;
    uint constant DEFAULT_STRATEGY_SHARE = 100;

    uint16 _managementFee; // The percent in basis points of profit that is charged as a fee.
    address feeRecipient; // The address to pay the `performanceFee` to.

    address _management;

    uint _totalAssets;

    mapping (BaseStrategy => uint) strategiesSharesMap;
    BaseStrategy[] strategies;

    constructor() ERC4626(IERC20(new AssetERC20("Asset Token", "ASSET"))) ERC20("Share Token", "SHARE") {
         // string memory name_, string memory symbol_  
    }

    /**
     * @dev Require that the call is coming from the strategies management.
     */
    modifier onlyManagement() {
        require(msg.sender == _management, "management");
        _;
    }



// Поддержка нескольких стратегий одним волтом.

    
    function totalAssets() public view override returns (uint256) {
        return _totalAssets;
    }

    function _withdraw( address caller, address receiver, address owner, uint256 assets, uint256 shares ) internal override {
        uint currentBalance = IERC20(asset()).balanceOf(address(this));
        if (currentBalance < assets){
        //     // если не хватит на этой стратегии?
            transferFrom(address(strategies[0]), address(this), assets - currentBalance);
        }
        
        super._withdraw(caller, receiver, owner, assets, shares);
    }

    function strategieBalance() public view returns(uint) {
        // return strategie.estimatedTotalAssets();
    }

    function remove(BaseStrategy strategy) external {
        // strategie.migrate(address(strategy)); // перевод с остновкойсо старой стратегии на другую
        // strategie = newStrategy;
    }
    function add(BaseStrategy strategy) external {
        // approve(address(newStrategy), balanceOf(address(this)));
        strategiesSharesMap[strategy] = DEFAULT_STRATEGY_SHARE; // или доля, или ничего, ждем менеджера, или принимать
    }
    function run(BaseStrategy strategy) external {}
    function pause(BaseStrategy strategy) external {}
    function unpause(BaseStrategy strategy) external {}

    // function setWithdrawalQueue(address[] queue) external {
    // }

    // вызывает БОТ
    function updateStrategyDeposit(BaseStrategy strategy) internal returns(uint maxAmount) {
        uint sharePersent = strategiesSharesMap[strategy];

        require(sharePersent != 0, "strategy not found");

        uint currentBalance = strategy.totalAssets();
        maxAmount = _totalAssets * sharePersent / 100;
        
        if (currentBalance < maxAmount) {
            strategy.deposit(maxAmount - currentBalance);

        } else if (currentBalance > maxAmount)  {
            strategy.withdraw(currentBalance - maxAmount);
        }
    }

    function setPersent(BaseStrategy strategy, uint sharePersent) external onlyManagement {
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
}