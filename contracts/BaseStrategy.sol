// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract BaseStrategy {
    address _vault;
    ERC20 _want;
    bool _active;
    bool _paused;
    string _name;

    constructor(address wantToken, string memory name) {
        _want = ERC20(wantToken);
        _name = name;
        _vault = msg.sender;
        _active = true;
    }
    // роли: бот, vault
    modifier onlyVault() {
        require(msg.sender == _vault, "only vault");
        _;
    }
    modifier onlyBot() {
        // require(msg.sender == , "only bot");
        _;
    }

    function withdraw(uint256 _amount) external virtual onlyVault returns(uint256) {
        // если не хватает забирает с адреса куда все инвестируется
        // иначе переводит с этого адреса
        require(_amount >= _want.balanceOf(address(this)), "not enaugth");

        return _withdraw(_amount);
    }

    function invest(uint256 _amountWant) external virtual onlyVault {
        // SafeERC20.safeTransferFrom(_want, address(this), КУДА, _amountWant);
        require(_amountWant >= _want.allowance(_vault, address(this)), "not enaugth allowance");

        _invest(_amountWant);
    }

    function _withdraw(uint256 _amount) internal virtual returns(uint256);

    function _invest(uint256 _amountWant) internal virtual;

    function harvestAndReport() external returns (uint256 _totalAssets) { // урожай и отчет
        // TODO: Implement harvesting logic and accurate accounting EX:
        //
        //      if(!TokenizedStrategy.isShutdown()) {
        //          _claimAndSellRewards();
        //      }
        //      _totalAssets = aToken.balanceOf(address(this)) + asset.balanceOf(address(this));
        //
        _totalAssets = _want.balanceOf(address(this));
    }
    function migrate(address _newStrategy) external virtual returns(address) {
        
    }

    function _emergencyWithdraw(uint256 _amount) internal {
        _paused = true;
        // _amount = min(_amount, aToken.balanceOf(address(this))); aToken - видимо это lp токены из pool-а 
        _withdraw(_amount);
        SafeERC20.safeTransferFrom(_want, address(this), _vault, _amount);
        
    }

    function pause() external virtual {
        _paused = true;
        // _withdraw(_want.balanceOf())  возвратом всех want-токенов на баланс стратегии
    }

    function unpause() external virtual {
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
    function isActive() external virtual view returns(bool) {
        return _active;
    }
}
