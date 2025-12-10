// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AssetERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import {Slots} from "./utils/elements.sol";

contract Vault is ERC4626, AccessControl, Slots{
    // CONSTANT //
    uint DEFAULT_PERFORMANCE_FEE = 1;
    // STRUCTS //
    struct StrategyParams {
        uint performanceFee;
        bool isActive;
        bool isPaused;
    }
    mapping(address => StrategyParams) public strategies;
    address[] public withdrawQueue;
    address feeRecipient;

    constructor() ERC4626(new AssetERC20("Asset Token", "ASSET")) ERC20("Share Token", "SHARE") { // string memory name_, string memory symbol_  
        role_manager = msg.sender; /////////////////////////////////////
        profit_max_unlock_time = 1 days; ///////////////////////////////
        feeRecipient = msg.sender;
    }

    function addStrategy(address newStrategy, bool addToQueue) external {
        require (newStrategy != address(0), "strategy cannot be zero address");
        require (IStrategy(newStrategy).asset() == asset(), "invalid asset");
        require (strategies[newStrategy].isActive, "strategy already active");
        require (strategies[newStrategy].isPaused, "strategy is paused");

        strategies[newStrategy] = StrategyParams(
            DEFAULT_PERFORMANCE_FEE,
            true,
            false
        );

        if (addToQueue){
            withdrawQueue.push(newStrategy);
        }
            
        emit StrategyChanged(newStrategy, StrategyChangeType.ADDED);
    }

    function revokeStratrgy(address strategy) external {
        require (strategies[strategy].isActive, "strategy not active");
        
        strategy.withdraw(strategy, address(this), IERC20(asset()).balanceOf(strategy));

        delete strategies[strategy];

        emit StrategyChanged(strategy, StrategyChangeType.REVOKED);
    }

    function pause(address strategy) external {
        _setPause(strategy, true);
    }

    function unpause(address strategy) external {
        _setPause(strategy, false);
    }

    function _setPause(address strategy, bool setPause) internal {
        require (strategy != address(0), "strategy cannot be zero address");
        strategies[strategy].isPaused = setPause;
    }

    function _withdraw( address caller, address receiver, address owner, uint256 assets, uint256 shares ) internal override {
        uint currentBalance = IERC20(asset()).balanceOf(address(this));

        if (currentBalance < assets){
            uint amount = assets - currentBalance;

            for (uint i = 0; i < withdrawQueue.length; i++) {
                address strategy = withdrawQueue[i];
                uint balance = IERC20(asset()).balanceOf(strategy);
                
                if (amount <= balance) {
                    transferFrom(strategy, address(this), amount);
                    break;
                } else {
                    transferFrom(strategy, address(this), balance);
                    amount -= balance;
                }
            }
        }
        
        super._withdraw(caller, receiver, owner, assets, shares);
    }

    function invest() external {}
    

    
    // EVENTS
    // STRATEGY EVENTS
    event StrategyChanged(
        address indexed strategy,
        Slots.StrategyChangeType indexed changeType
    );

    event StrategyReported(
        address indexed strategy,
        uint256 gain,
        uint256 loss,
        uint256 currentDebt,
        uint256 protocolFees,
        uint256 totalFees,
        uint256 totalRefunds
    );

    // DEBT MANAGEMENT EVENTS
    event DebtUpdated(
        address indexed strategy,
        uint256 currentDebt,
        uint256 newDebt
    );

    // ROLE UPDATES
    event RoleSet(
        address indexed account,
        Slots.Roles indexed role
    );

    // STORAGE MANAGEMENT EVENTS
    event UpdateFutureRoleManager(
        address indexed futureRoleManager
    );

    event UpdateRoleManager(
        address indexed roleManager
    );

    event UpdateAccountant(
        address indexed accountant
    );

    event UpdateDepositLimitModule(
        address indexed depositLimitModule
    );

    event UpdateWithdrawLimitModule(
        address indexed withdrawLimitModule
    );

    event UpdateDefaultQueue(
        address[] newDefaultQueue
    );

    event UpdateUseDefaultQueue(
        bool useDefaultQueue
    );

    event UpdateAutoAllocate(
        bool autoAllocate
    );

    event UpdatedMaxDebtForStrategy(
        address indexed sender,
        address indexed strategy,
        uint256 newDebt
    );

    event UpdateDepositLimit(
        uint256 depositLimit
    );

    event UpdateMinimumTotalIdle(
        uint256 minimumTotalIdle
    );

    event UpdateProfitMaxUnlockTime(
        uint256 profitMaxUnlockTime
    );

    event DebtPurchased(
        address indexed strategy,
        uint256 amount
    );
}

interface IStrategy {
    function asset() external view returns(address);
    function vault() external view returns(address);
    function isActive() external view returns(bool);
    function delegatedAssets() external view returns(uint256);
    function estimatedTotalAssets() external view returns(uint256);
    function withdraw(uint256 _amount ) external returns(uint256);
    function migrate(address _newStrategy) external returns(address);
}
// interface HealthCheck {
//     function check(address strategy, uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding, uint256 totalDebt) external view returns(bool);
//     function doHealthCheck(strategy: address) -> bool: view
//     function enableCheck(strategy: address): nonpayable
// }

interface BotManage {
}