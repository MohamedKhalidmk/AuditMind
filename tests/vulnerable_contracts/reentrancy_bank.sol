// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VulnerableBank {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // VULNERABLE: sends ETH before updating balance (classic reentrancy)
    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "insufficient balance");

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "transfer failed");

        balances[msg.sender] -= amount; // state update AFTER external call
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
