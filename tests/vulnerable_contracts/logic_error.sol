// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// This contract has NO reentrancy, NO missing access control, NO overflow --
// it compiles cleanly and Slither should find little to nothing here.
// The bug is purely in the LOGIC: the liquidation threshold math is wrong.
// This is the exact class of bug that requires LLM reasoning about INTENT,
// not pattern matching. (Modeled after the Compound distribution bug logic.)

contract VulnerableLendingLogic {
    mapping(address => uint256) public collateralValue; // in USD, 18 decimals
    mapping(address => uint256) public borrowedValue;    // in USD, 18 decimals

    // INTENDED behavior (per the function name and typical DeFi convention):
    // liquidate if collateral < 150% of borrowed value (i.e. collateral
    // ratio has fallen below the safe 1.5x threshold).
    //
    // ACTUAL bug: multiplying borrowedValue by 1 instead of 1.5 (150/100
    // was intended, but implemented as just "borrowedValue", dropping the
    // multiplier entirely) -- this means positions are only liquidated once
    // they are already 100% undercollateralized, not 150%. Real losses
    // accumulate silently until it's too late to recover full value.
    function shouldLiquidate(address user) public view returns (bool) {
        return collateralValue[user] < borrowedValue[user]; // <- BUG: missing * 150 / 100
    }
}
