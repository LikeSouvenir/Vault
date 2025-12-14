// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import {IFeeConfig} from "./interfaces/IFeeConfig.sol";

abstract contract BaseStrategy is ReentrancyGuard, AccessControl {
    address immutable _vault; // default manager
    ERC20 immutable _asset;
    string _name;
    uint _lastTotalAssets;
    
    bytes32 constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    constructor(
        address assetToken_,
        string memory name_,    
        address vault_
    ) {
        _asset = ERC20(assetToken_);
        _name = name_;
        _vault = vault_;

        SafeERC20.forceApprove(_asset, _vault, type(uint256).max);// проверять при добавлении в addStrategy
        
        _grantRole(DEFAULT_ADMIN_ROLE, vault_);
    }
    /**
    все поля инициализированны
    get & set методы
    events
    Access Control
 */

    modifier onlyVault() {
        require(msg.sender == _vault, "vault");
        _;
    }

    function push(uint256 _amount) external virtual nonReentrant onlyVault{
        SafeERC20.safeTransfer(_asset, address(this), _amount);

        _push(_amount);
        _lastTotalAssets += _amount;

        emit Deposit(_amount);
    }

    function pull(uint256 _amount) external virtual nonReentrant onlyVault returns(uint256 value) {
        uint available = _harvestAndReport();
        require(_amount <= available, "insufficient assets");

        value = _pull(_amount);
        _lastTotalAssets -= value;

        SafeERC20.safeTransfer(_asset, _vault, _amount);

        emit Withdraw(value);
    }

    function report() external nonReentrant onlyRole(KEEPER_ROLE) returns(uint256 profit, uint256 loss) {
        uint newTotalAssets = _harvestAndReport();

        // Calculate profit/loss.
        if (newTotalAssets > _lastTotalAssets) {
            profit = newTotalAssets - _lastTotalAssets;
        } else {
            loss = newTotalAssets - _lastTotalAssets;
        }
        _lastTotalAssets = newTotalAssets;

        emit Report(block.timestamp, profit, loss);
    }

    function _pull(uint256 _amount) internal virtual returns(uint256);

    function _push(uint256 _amount) internal virtual;

    function _harvestAndReport() internal virtual returns(uint256 _totalAssets);

    function asset() external virtual view returns(address) {
        return address(_asset);
    }

    function vault() external virtual view returns(address) {
        return _vault;
    }
    
    event Withdraw(uint256 assetWithdraw);
    
    event Deposit(uint256 assetWithdraw);
    
    event Report(uint indexed time, uint256 indexed profit, uint256 indexed loss);
}
