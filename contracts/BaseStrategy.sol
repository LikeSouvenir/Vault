// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.33;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

interface IVault {
    function report(BaseStrategy strategy) external;
    function rebalance(BaseStrategy strategy) external;
    function strategyBalance(BaseStrategy strategy) external view returns(uint);
}

abstract contract BaseStrategy is ReentrancyGuard, AccessControl {
    address immutable _vault; // default manager/keeper
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
        _vault = vault_;
        _name = name_;

        SafeERC20.forceApprove(_asset, _vault, type(uint256).max);
        
        _grantRole(DEFAULT_ADMIN_ROLE, vault_);
        _grantRole(KEEPER_ROLE, vault_);
    }

    function _pull(uint256 amount) internal virtual returns(uint256);

    function _push(uint256 amount) internal virtual;

    function _harvestAndReport() internal virtual returns(uint256 _totalAssets);

    function reportAndInvest() external virtual onlyRole(KEEPER_ROLE) {
        IVault(_vault).report(this);
        IVault(_vault).rebalance(this);
    }

    function push(uint256 amount) external virtual onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant{
        SafeERC20.safeTransferFrom(_asset, msg.sender, address(this), amount);

        _push(amount);
        _lastTotalAssets += amount;
        
        emit Push(amount);
    }

    function pull(uint256 amount) external virtual onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant returns(uint256 value) {
        uint available = IVault(_vault).strategyBalance(this);
        require(amount <= available, "insufficient assets");

        _lastTotalAssets -= amount;
        value = _pull(amount);

        SafeERC20.safeTransfer(_asset, msg.sender, value);

        emit Pull(value);
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

    function teakeAndClose() external onlyRole(DEFAULT_ADMIN_ROLE) returns(uint amount) {
        amount = _withdraw();
    }

    function emergencyWithdraw() external onlyRole(DEFAULT_ADMIN_ROLE) returns(uint amount) {
        _withdraw();

        emit EmergencyWithdraw(block.timestamp, amount);
    }

    function _withdraw() internal returns(uint amount) {
        amount = ERC20(_asset).balanceOf(address(this));

        if (!_isPaused) {
            _isPaused = true;
            uint assetAmount = _harvestAndReport();
            _pull(assetAmount - amount);
        }

        amount = ERC20(_asset).balanceOf(address(this));
        SafeERC20.safeTransfer(
            ERC20(_asset), 
            address(_vault), 
            amount
        );
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE)  {
        _isPaused = true;
        uint assetAmount = IVault(_vault).strategyBalance(this);
        _pull(assetAmount);

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
    
    event Pull(uint256 assetPull);
    
    event Push(uint256 assetPush);
    
    event Report(uint indexed time, uint256 indexed profit, uint256 indexed loss);
    
    event EmergencyWithdraw(uint timestamp, uint amount);
}
