// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Slots {

    constructor() {}

    // STRUCTS //
    struct StrategyParams {
        uint256 activation; 
        uint256 last_report;
        uint256 current_debt;
        uint256 max_debt;
    }

    // CONSTANTS //
    uint256 constant MAX_QUEUE = 10;
    uint256 constant MAX_BPS = 10_000;
    uint256 constant MAX_BPS_EXTENDED = 1_000_000_000_000;

    // ENUMS //
    // Each permissioned function has its own Role.
    // Roles can be combined in any combination or all kept separate.
    // Follows python Enum patterns so the first Enum == 1 and doubles each time.
    enum Roles{
        ADD_STRATEGY_MANAGER, // Can add strategies to the vault.
        REVOKE_STRATEGY_MANAGER, // Can remove strategies from the vault.
        FORCE_REVOKE_MANAGER, // Can force remove a strategy causing a loss.
        ACCOUNTANT_MANAGER, // Can set the accountant that assess fees.
        QUEUE_MANAGER, // Can set the default withdrawal queue.
        REPORTING_MANAGER, // Calls report for strategies.
        DEBT_MANAGER, // Adds and removes debt from strategies.
        MAX_DEBT_MANAGER, // Can set the max debt for a strategy.
        DEPOSIT_LIMIT_MANAGER, // Sets deposit limit and module for the vault.
        WITHDRAW_LIMIT_MANAGER, // Sets the withdraw limit module.
        MINIMUM_IDLE_MANAGER, // Sets the minimum total idle the vault should keep.
        PROFIT_UNLOCK_MANAGER, // Sets the profit_max_unlock_time.
        DEBT_PURCHASER, // Can purchase bad debt from the vault.
        EMERGENCY_MANAGER // Can shutdown vault in an emergency.
    }

    enum StrategyChangeType{
        ADDED,
        REVOKED
    }

    enum Rounding{
        ROUND_DOWN,
        ROUND_UP
    }

    // STORAGE //
    address public asset;
    uint8 public decimals;
    address factory;

    mapping(address => StrategyParams) public strategies;
    address[MAX_QUEUE] public default_queue;
    bool public use_default_queue;
    bool public auto_allocate;

    ////// ACCOUNTING //////
    uint256 total_debt;
    uint256 total_idle;
    uint256 public minimum_total_idle;
    uint256 public deposit_limit;

    ////// PERIPHERY //////
    address public accountant;
    address public deposit_limit_module;
    address public withdraw_limit_module;

    ////// ROLES //////
    mapping(address => Roles) public roles;
    address public role_manager;
    address public future_role_manager;

    bool shutdown;
    uint256 profit_max_unlock_time;
    uint256 full_profit_unlock_date;
    uint256 profit_unlocking_rate;
    uint256 last_profit_update;

    mapping(address => uint256) public nonces;
    bytes32 constant DOMAIN_TYPE_HASH = keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');
    bytes32 constant PERMIT_TYPE_HASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

}