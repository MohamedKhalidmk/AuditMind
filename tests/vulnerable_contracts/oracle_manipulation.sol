// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapPool {
    function getSpotPrice() external view returns (uint256);
}

contract VulnerableLending {
    IUniswapPool public priceOracle;
    mapping(address => uint256) public collateral;
    mapping(address => uint256) public borrowed;

    constructor(address _pool) {
        priceOracle = IUniswapPool(_pool);
    }

    function depositCollateral(uint256 amount) public {
        collateral[msg.sender] += amount;
    }

    // VULNERABLE: uses a single spot price read directly from a DEX pool.
    // A flash loan can manipulate this price within the same transaction
    // before this function is called (see Mango Markets exploit pattern).
    function borrow(uint256 amount) public {
        uint256 price = priceOracle.getSpotPrice(); // <- manipulable spot price
        uint256 collateralValue = collateral[msg.sender] * price;
        require(collateralValue >= amount * 150 / 100, "insufficient collateral");
        borrowed[msg.sender] += amount;
        // ... transfer borrowed amount to msg.sender
    }
}
