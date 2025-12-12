// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IFeeConfig} from "./interfaces/IFeeConfig.sol";

abstract contract BaseStrategy is ReentrancyGuard {
    uint constant BPS = 10_000;
    uint16 constant DEFAULT_FEE = 200;
    
    /// @notice Seconds per year for max profit unlocking time.
    uint256 internal constant SECONDS_PER_YEAR = 31_556_952; // 365.2425 days
    uint constant TWELVE_MONTHS = 12;

    uint _totalAssets;

    address _vault; // default manager
    ERC20 _asset;
    bool _paused;
    uint16 _performanceFee = DEFAULT_FEE; // The percent in basis points of profit that is charged as a fee.
    string _name;
    
    address _management; // Main address that can set all configurable variables.
    address _keeper; // Address given permission to call 

    uint lastTakeTime;

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

        SafeERC20.forceApprove(_asset, _vault, type(uint256).max);// проверять при добавлении в addStrategy

        lastTakeTime = block.timestamp;
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
        require(_paused == false, "is paused");
        _;
    }

    function withdraw(uint256 _amount) external virtual nonReentrant onlyKeeperOrManagement notPaused returns(uint256 value) {
        uint available = _harvestAndReport();
        require(_amount <= available, "insufficient assets");

        value = _withdraw(_amount);

        _totalAssets = available - _amount;
    }

    function deposit(uint256 _amountAsset) external virtual onlyKeeperOrManagement notPaused{
        require(_amountAsset >= _asset.allowance(_vault, address(this)), "not enaugth allowance");
        SafeERC20.safeTransferFrom(_asset, _vault, address(this), _amountAsset);


        _deposit(_amountAsset);

        _totalAssets += _amountAsset;
    }

    event Report(uint indexed time, uint256 indexed profit, uint256 indexed loss, uint256 performanceFees);

    function report() external nonReentrant onlyKeeperOrManagement returns(uint256 profit, uint256 loss) {
        uint newTotalAssets = _harvestAndReport();
        uint currentFee;

        // Calculate profit/loss.
        if (newTotalAssets > _totalAssets) {
            (uint16 managementFee, address feeRecipient) = IFeeConfig(_vault).feeConfig();
            profit = newTotalAssets - _totalAssets;
            
            currentFee = (profit * _performanceFee) / BPS;

            if (managementFee != 0) {
                uint oneMonth = SECONDS_PER_YEAR / TWELVE_MONTHS;

                // ДОЛЖНО БЫТЬ ВЫЗВАНО НЕ ЧАЩИ 1 РАЗА В МЕСЯЦ   
                //  если report вызывается реже или чаще, то managementFee будет неадекватным.
                if (block.timestamp >= lastTakeTime) {
                    lastTakeTime = block.timestamp + oneMonth;

                    uint currentManagementFee  = ((newTotalAssets * managementFee) / BPS) / TWELVE_MONTHS;
                    
                    currentFee += currentManagementFee;
                }
            }

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

        _totalAssets = newTotalAssets - currentFee;

        emit Report(block.timestamp, profit, loss, currentFee);
    }

    function _withdraw(uint256 _amount) internal virtual returns(uint256);

    function _deposit(uint256 _amountAsset) internal virtual;

    function _harvestAndReport() internal virtual returns(uint256 _totalAssets);

    function migrate(BaseStrategy _newStrategy) external virtual onlyManagement returns(uint _amountAssets) {
        _amountAssets = _harvestAndReport();
        _withdraw(_amountAssets);

        _newStrategy.deposit(_asset.balanceOf(address(this)));

        _totalAssets = 0;
    }

    function emergencyWithdraw() external onlyManagement virtual returns(uint _amount) {
        _amount = _lockAndTake();

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

    function setPerformanceFee(uint16 newFee) external onlyManagement {
        require(newFee >= uint16(1), "min % is 0,01");
        _performanceFee = newFee;
    }

    function performanceFee() external view returns(uint16) {
        return _performanceFee;
    }
}
