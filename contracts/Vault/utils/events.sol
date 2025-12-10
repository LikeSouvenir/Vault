// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Slots} from "./elements.sol";

contract Events {

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

    // event Shutdown();
}
