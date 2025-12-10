// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IFeeConfig} from "./interfaces/IFeeConfig.sol";

abstract contract BaseStrategy is ReentrancyGuard {
    uint constant TWELVE_MONTHS = 12;
    uint _bps = 10_000;
    uint _totalAssets;

    address _vault; // default manager
    ERC20 _asset;
    bool _paused;
    uint16 _performanceFee; // The percent in basis points of profit that is charged as a fee.
    string _name;
    
    address _management; // Main address that can set all configurable variables.
    address _keeper; // Address given permission to call {report} and {tend}.

    constructor(
        address assetToken,
        string memory name,    
        address management,
        address keeper, // BOT,
        address vaultAddr
    ) {
        _asset = ERC20(assetToken);
        _name = name;
        _management = management;
        _keeper = keeper;
        _vault = vaultAddr;

        // SafeERC20.forceApprove(_asset, _vault, type(uint256).max);
    }

    /**
     * @dev Require that the call is coming from the strategies management.
     */
    modifier onlyManagement() {
        require(msg.sender == _management || msg.sender == _vault, "management");
        _;
    }

    /**
     * @dev Require that the call is coming from either the strategies
     * management or the keeper.
     */
    modifier onlyKeeperOrManagement() {
        require(msg.sender == _keeper || msg.sender == _management || msg.sender == _vault, "keeper");
        _;
    }

    modifier notPaused() {
        require(_paused = false, "is paused");
        _;
    }

    function withdraw(uint256 _amount) external virtual nonReentrant onlyKeeperOrManagement returns(uint256) {
        uint _amountAssets = _harvestAndReport();
        require(_amount > _amountAssets, "not enaugth");

        return _withdraw(_amount);
    }

    function deposit(uint256 _amountAsset) external virtual onlyKeeperOrManagement notPaused{
        require(_amountAsset >= _asset.allowance(_vault, address(this)), "not enaugth allowance");
        SafeERC20.safeTransferFrom(_asset, msg.sender, address(this), _amountAsset);

        _deposit(_amountAsset);
    }

    event Report(uint indexed time, uint256 indexed profit, uint256 indexed loss, uint256 performanceFees);

    function report() external nonReentrant onlyKeeperOrManagement returns (uint256 profit, uint256 loss) {
        uint newTotalAssets = _harvestAndReport();
        uint currentFee;

        // Calculate profit/loss.
        if (newTotalAssets > _totalAssets) {
            (uint16 managementFee, address feeRecipient) = IFeeConfig(_vault).feeConfig();
            profit = newTotalAssets - _totalAssets;
            
            uint currentPerformanceFee = (profit * _performanceFee) / _bps;
            uint currentManagementFee  = ((newTotalAssets * managementFee) / _bps) / TWELVE_MONTHS;
            currentFee = currentManagementFee + currentPerformanceFee;

            if (currentFee != 0) {
                if (profit < currentFee) {
                    currentFee = profit;
                }

                _withdraw(currentFee);

                _asset.transfer(feeRecipient, currentFee);
            }
        } else {
            loss = _totalAssets - newTotalAssets;
        }

        _totalAssets = newTotalAssets;

        emit Report(block.timestamp, profit, loss, currentFee);
    }

    function _withdraw(uint256 _amount) internal virtual returns(uint256);

    function _deposit(uint256 _amountAsset) internal virtual;

    function _harvestAndReport() internal virtual returns(uint256 _totalAssets);

    function migrate(address _newStrategy) external virtual onlyManagement returns(uint _amountAssets) {
        _amountAssets = _harvestAndReport();
        _withdraw(_amountAssets);

        BaseStrategy(_newStrategy).deposit(_asset.balanceOf(address(this)));
    }

    function emergencyWithdraw() external onlyManagement virtual {
        uint _amount = _lockAndTake();

        SafeERC20.safeTransferFrom(_asset, address(this), _vault, _amount);
    }

    function pause() public virtual onlyKeeperOrManagement notPaused returns(uint _amountAssets) {
        _amountAssets = _lockAndTake();
    }

    function _lockAndTake() internal returns(uint _amountAssets) {
        _paused = true;

        _amountAssets = _harvestAndReport();
        _withdraw(_amountAssets);
    }

    function unpause() external virtual onlyManagement {
        _paused = false;
    }

    function asset() external virtual view returns(address) {
        return address(_asset);
    }


    function totalAssets() external virtual view returns(uint) {
        return _totalAssets;
    }

    function vault() external virtual view returns(address) {
        return _vault;
    }

    function isPaused() external virtual view returns(bool) {
        return _paused;
    }
}
