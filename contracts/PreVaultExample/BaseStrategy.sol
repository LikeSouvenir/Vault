// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IFeeConfig} from "./interfaces/IFeeConfig.sol";

abstract contract BaseStrategy is ReentrancyGuard, IFeeConfig {
    uint constant TWELVE_MONTHS = 12;
    uint _bps = 10_000;
    uint totalAssets;

    address _vault; // default manager
    ERC20 _want;
    bool _paused;
    uint16 _performanceFee; // The percent in basis points of profit that is charged as a fee.
    string _name;
    
    address _management; // Main address that can set all configurable variables.
    address _keeper; // Address given permission to call {report} and {tend}.

    constructor(
        address wantToken,
        string memory name,    
        address management,
        address keeper, // BOT,
        address vaultAddr
    ) {
        _want = ERC20(wantToken);
        _name = name;
        _management = management;
        _keeper = keeper;
        _vault = vaultAddr;

        // SafeERC20.forceApprove(_want, _vault, type(uint256).max);
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
        uint _totalAssets = _harvestAndReport();
        require(_amount > _totalAssets, "not enaugth");

        return _withdraw(_amount);
    }

    function deposit(uint256 _amountWant) external virtual onlyKeeperOrManagement notPaused{
        require(_amountWant >= _want.allowance(_vault, address(this)), "not enaugth allowance");

        _deposit(_amountWant);
    }

    event Report(uint indexed time, uint256 indexed profit, uint256 indexed loss, uint256 performanceFees);

    function report() external nonReentrant onlyKeeperOrManagement returns (uint256 profit, uint256 loss) {
        uint newTotalAssets = _harvestAndReport();
        uint currentFee;

        // Calculate profit/loss.
        if (newTotalAssets > totalAssets) {
            (uint16 managementFee, address feeRecipient) = IFeeConfig(_vault).feeConfig();
            profit = newTotalAssets - totalAssets;
            
            uint currentPerformanceFee = (profit * _performanceFee) / _bps;
            uint currentManagementFee  = ((newTotalAssets * managementFee) / _bps) / TWELVE_MONTHS;
            currentFee = currentManagementFee + currentPerformanceFee;

            if (currentFee != 0) {

                if (profit < currentFee) {
                    currentFee = profit;
                }

                _withdraw(currentFee);

                _want.transfer(feeRecipient, currentFee);
            }
        } else {
            loss = totalAssets - newTotalAssets;
        }

        totalAssets = newTotalAssets;

        emit Report(block.timestamp, profit, loss, currentFee);
    }

    function _withdraw(uint256 _amount) internal virtual returns(uint256);

    function _deposit(uint256 _amountWant) internal virtual;

    function _harvestAndReport() internal virtual returns(uint256 _totalAssets);

    function migrate(address _newStrategy) external virtual onlyManagement returns(uint _totalAssets) {
        _totalAssets = _harvestAndReport();
        _withdraw(_totalAssets);

        BaseStrategy(_newStrategy).deposit(_want.balanceOf(address(this)));
    }

    function emergencyWithdraw() external onlyManagement virtual {
        uint _amount = _lockAndTake();

        SafeERC20.safeTransferFrom(_want, address(this), _vault, _amount);
    }

    function pause() public virtual onlyKeeperOrManagement notPaused returns(uint _totalAssets) {
        _totalAssets = _lockAndTake();
    }

    function _lockAndTake() internal returns(uint _totalAssets) {
        _paused = true;

        _totalAssets = _harvestAndReport();
        _withdraw(_totalAssets);
    }

    function unpause() external virtual onlyManagement {
        _paused = false;
    }

    function want() external virtual view returns(address) {
        return address(_want);
    }

    function vault() external virtual view returns(address) {
        return _vault;
    }

    function isPaused() external virtual view returns(bool) {
        return _paused;
    }
}
