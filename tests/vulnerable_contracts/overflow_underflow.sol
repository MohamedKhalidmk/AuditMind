// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
// NOTE: deliberately using pre-0.8.0 Solidity -- no automatic overflow checks

contract VulnerableTokenOld {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // VULNERABLE: no check that sender actually has enough balance.
    // In Solidity <0.8.0, this underflows silently instead of reverting.
    function transfer(address to, uint256 amount) public {
        balances[msg.sender] -= amount;  // underflows to a huge number if amount > balance
        balances[to] += amount;
    }
}
