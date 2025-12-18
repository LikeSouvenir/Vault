// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import {IFeeConfig} from "./interfaces/IFeeConfig.sol";

interface IVault {
    function report(BaseStrategy strategy) external;
    function rebalance(BaseStrategy strategy) external returns(uint amount);
}

abstract contract BaseStrategy is ReentrancyGuard, AccessControl {
    address immutable _vault; // default manager
    ERC20 immutable _asset;

    uint _lastTotalAssets;
    string _name;
    bool _isPaused;

    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    constructor(
        address assetToken_,
        string memory name_,    
        address vault_
    ) {
        _asset = ERC20(assetToken_);
        _name = name_;
        _vault = vault_;

        SafeERC20.forceApprove(_asset, _vault, type(uint256).max);
        
        _grantRole(DEFAULT_ADMIN_ROLE, vault_);
        _grantRole(KEEPER_ROLE, vault_);
    }

    function _pull(uint256 _amount) internal virtual returns(uint256);

    function _push(uint256 _amount) internal virtual;

    function _harvestAndReport() internal virtual returns(uint256 _totalAssets);

    function reportAndInvest() external virtual onlyRole(KEEPER_ROLE) {
        IVault(_vault).report(this);
        IVault(_vault).rebalance(this);
    }

    function push(uint256 _amount) external virtual onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant{
        SafeERC20.safeTransferFrom(_asset, msg.sender, address(this), _amount);

        _push(_amount);
        _lastTotalAssets += _amount;
        
        emit Deposit(_amount);
    }

    function pull(uint256 _amount) external virtual onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant returns(uint256 value) {
        uint available = _harvestAndReport();
        require(_amount <= available, "insufficient assets");

        _lastTotalAssets -= _amount;
        value = _pull(_amount);

        SafeERC20.safeTransfer(_asset, msg.sender, value);

        emit Withdraw(value);
    }

    function report() external virtual nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) returns(uint256 profit, uint256 loss) {
        uint newTotalAssets = _harvestAndReport();

        // Calculate profit/loss.
        if (newTotalAssets > _lastTotalAssets) {
            profit = newTotalAssets - _lastTotalAssets;
        } else {
            loss = _lastTotalAssets - newTotalAssets;
        }
        _lastTotalAssets = newTotalAssets;

        emit Report(block.timestamp, profit, loss);
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE)  {
        uint newTotalAssets = _harvestAndReport();
        _isPaused = true;
        _pull(newTotalAssets);

        emit StrategyPaused(block.timestamp);
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE)  {
        _isPaused = false;
        _push(_asset.balanceOf(address(this)));

        emit StrategyUnpaused(block.timestamp);
    }

    function isPaused() external virtual view returns(bool) {
        return _isPaused;
    }

    function asset() external virtual view returns(address) {
        return address(_asset);
    }

    function vault() external virtual view returns(address) {
        return _vault;
    }

    function lastTotalAssets() external virtual view returns(uint) {
        return _lastTotalAssets;
    }

    function name() external virtual view returns(string memory) {
        return _name;
    }

    event StrategyUnpaused(uint indexed timestamp);

    event StrategyPaused(uint indexed timestamp);
    
    event Withdraw(uint256 assetWithdraw);
    
    event Deposit(uint256 assetWithdraw);
    
    event Report(uint indexed time, uint256 indexed profit, uint256 indexed loss);
}
