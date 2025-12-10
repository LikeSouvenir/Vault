// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IStrategy {
    function want() external view returns(address); 
    function vault() external view returns(address);  
    function isActive() external view returns(bool);
    function delegatedAssets() external view returns(uint256);// делегированные активы
    function estimatedTotalAssets() external view returns(uint256);// Оценочные общие активы
    function withdraw(uint256 _amount ) external returns(uint256);
    function migrate(address _newStrategy) external returns(address);
}

contract Strategy is IStrategy {
    bool _active;
    IERC20 _want;
    address _vault;

    constructor(address want_, address vault_) {
        _want = IERC20(want_);
        _vault = vault_;
        SafeERC20.forceApprove(_want, _vault, type(uint256).max);

    }
    function delegatedAssets() external view returns(uint256) {}
    function estimatedTotalAssets() external view returns(uint256) {}
    function withdraw(uint256 _amount ) external returns(uint256) {}
    function migrate(address _newStrategy) external returns(address) {}

    function want() external view returns(address) {
        return address(_want);
    }
    function vault() external view returns(address) {
        return _vault;
    }
    function isActive() external view returns(bool) {
        return _active;
    }

    /*
    ввод и вывод стредств например в Aave, Compound, Curve
    */

}
