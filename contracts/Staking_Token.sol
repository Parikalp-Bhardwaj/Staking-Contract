// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract StakingToken is ERC20{
    uint8 public _decimals = 8;
    uint256 public _totalSupply = 500000000 * (10 ** uint256(_decimals));
    constructor()ERC20("Staking Token","STT"){
        _mint(msg.sender, _totalSupply);
    }
}