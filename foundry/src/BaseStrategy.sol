// SPDX-License-Identifier: SEE LICENSE IN LICENSE
// pragma solidity 0.8.33;
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

import {IVault} from "./interfaces/IVault.sol";
import {IBaseStrategy} from "./interfaces/IBaseStrategy.sol";

/**
 * @title Base Abstract Strategy Contract
 * @dev All concrete strategies should inherit from this contract and implement virtual functions
 */
abstract contract BaseStrategy is IBaseStrategy, ReentrancyGuard, AccessControl {
    /// @notice Vault address
    /// @dev default manager/keeper
    address internal immutable _vault;
    /// @notice Underlying asset of the strategy
    IERC20 internal immutable _asset;
    /// @notice Last recorded total asset balance
    uint256 private _lastTotalAssets;
    /// @notice Strategy name
    string private _name;
    /// @notice Strategy pause flag
    bool internal _isPaused;
    /// @notice Keeper role (bot/operator)
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    /**
     * @notice Creates a new base strategy
     * @param assetToken_ Address of the underlying asset
     * @param name_ Strategy name
     * @param vault_ Vault address
     * @custom:requires assetToken_ must not be zero address
     * @custom:requires vault_ must not be zero address
     */
    constructor(address assetToken_, string memory name_, address vault_) {
        require(assetToken_ != address(0), "assetToken zero address");
        require(vault_ != address(0), "vault zero address");

        _asset = IERC20(assetToken_);
        _vault = vault_;
        _name = name_;

        SafeERC20.forceApprove(_asset, _vault, type(uint256).max);

        _grantRole(DEFAULT_ADMIN_ROLE, vault_);
        _grantRole(KEEPER_ROLE, vault_);
    }

    /**
     * @notice Withdraw assets from strategy (internal implementation)
     * @dev Must be implemented in derived contracts
     * @param amount Amount of assets to withdraw
     * @return Actual amount withdrawn
     */
    function _pull(uint256 amount) internal virtual returns (uint256);

    /**
     * @notice Deposit assets into strategy (internal implementation)
     * @dev Must be implemented in derived contracts
     * @param amount Amount of assets to deposit
     */
    function _push(uint256 amount) internal virtual;

    /**
     * @notice Harvest profits and report balance (internal implementation)
     * @dev Must be implemented in derived contracts
     * @return _totalAssets Current total asset balance in strategy
     */
    function _harvestAndReport() internal virtual returns (uint256 _totalAssets);

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, IERC165) returns (bool) {
        return interfaceId == type(IBaseStrategy).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IBaseStrategy
     * @custom:modifier onlyRole(DEFAULT_ADMIN_ROLE) Only administrator
     * @custom:modifier nonReentrant Reentrancy protection
     * @custom:emits Push
     */
    function push(uint256 amount) external virtual onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        SafeERC20.safeTransferFrom(_asset, msg.sender, address(this), amount);

        _push(amount);
        _lastTotalAssets += amount;

        emit Push(amount);
    }

    /**
     * @inheritdoc IBaseStrategy
     * @custom:modifier onlyRole(DEFAULT_ADMIN_ROLE) Only administrator
     * @custom:modifier nonReentrant Reentrancy protection
     * @custom:requires Requested amount must not exceed available balance
     * @custom:emits Pull
     */
    function pull(uint256 amount) external virtual onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant returns (uint256 value) {
        require(amount <= _lastTotalAssets, "insufficient assets");

        _lastTotalAssets -= amount;
        value = _pull(amount);

        SafeERC20.safeTransfer(_asset, msg.sender, value);

        emit Pull(value);
    }

    /**
     * @inheritdoc IBaseStrategy
     * @custom:modifier nonReentrant Reentrancy protection
     * @custom:modifier onlyRole(DEFAULT_ADMIN_ROLE) Only administrator
     * @custom:emits Report
     */
    function report()
    external
    virtual
    nonReentrant
    onlyRole(DEFAULT_ADMIN_ROLE)
    returns (uint256 profit, uint256 loss)
    {
        uint256 newTotalAssets = _harvestAndReport();

        // Calculate profit/loss.
        if (newTotalAssets > _lastTotalAssets) {
            profit = newTotalAssets - _lastTotalAssets;
        } else {
            loss = _lastTotalAssets - newTotalAssets;
        }
        _lastTotalAssets = newTotalAssets;

        emit Report(block.timestamp, profit, loss);
    }

    /**
     * @inheritdoc IBaseStrategy
     * @custom:modifier onlyRole(DEFAULT_ADMIN_ROLE) Only administrator
     */
    function takeAndClose() external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256 amount) {
        amount = _emergencyWithdraw();
    }

    /**
     * @inheritdoc IBaseStrategy
     * @notice Pauses the strategy, withdraws all assets to contract
     * @custom:modifier onlyRole(DEFAULT_ADMIN_ROLE) Only administrator
     * @custom:emits EmergencyWithdraw
     */
    function emergencyWithdraw() external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256 amount) {
        amount = _emergencyWithdraw();

        emit EmergencyWithdraw(block.timestamp, amount);
    }

    function _emergencyWithdraw() internal returns (uint256 amount) {
        if (!_isPaused) {
            uint256 total = _harvestAndReport();
            if (total > 0) {
                _pull(total);
            }
        }

        amount = IERC20(_asset).balanceOf(address(this));
        SafeERC20.safeTransfer(IERC20(_asset), address(_vault), amount);
        _isPaused = true;
    }

    /**
     * @inheritdoc IBaseStrategy
     * @notice Pauses the strategy, withdraws all assets to contract
     * @custom:modifier onlyRole(DEFAULT_ADMIN_ROLE) Only administrator
     * @custom:emits StrategyPaused
     */
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _isPaused = true;
        uint256 assetAmount = _harvestAndReport();
        _pull(assetAmount);

        emit StrategyPaused(block.timestamp);
    }

    /**
     * @inheritdoc IBaseStrategy
     * @custom:modifier onlyRole(DEFAULT_ADMIN_ROLE) Only administrator
     * @custom:emits StrategyUnpaused
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _isPaused = false;
        _push(_asset.balanceOf(address(this)));

        emit StrategyUnpaused(block.timestamp);
    }

    /**
     * @inheritdoc IBaseStrategy
     */
    function isPaused() external view virtual returns (bool) {
        return _isPaused;
    }

    /**
     * @inheritdoc IBaseStrategy
     */
    function asset() external view virtual returns (address) {
        return address(_asset);
    }

    /**
     * @inheritdoc IBaseStrategy
     */
    function vault() external view virtual returns (address) {
        return _vault;
    }

    /**
     * @inheritdoc IBaseStrategy
     */
    function lastTotalAssets() external view virtual returns (uint256) {
        return _lastTotalAssets;
    }

    /**
     * @inheritdoc IBaseStrategy
     */
    function name() external view virtual returns (string memory) {
        return _name;
    }
}
