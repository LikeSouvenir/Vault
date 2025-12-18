// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Erc20Mock is ERC20{
    constructor() ERC20("MockToken", "MT") {}

    function mint(address account, uint256 value) external {
        _update(address(0), account, value);
    }

    function burn(address account, uint256 value) external {
        _update(account, address(0), value);
    }
    
}