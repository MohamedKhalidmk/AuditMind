// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VulnerableToken {
    mapping(address => uint256) public balances;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // VULNERABLE: no access control -- ANYONE can mint unlimited tokens
    function mint(address to, uint256 amount) public {
        balances[to] += amount;
    }

    function transfer(address to, uint256 amount) public {
        require(balances[msg.sender] >= amount, "insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
