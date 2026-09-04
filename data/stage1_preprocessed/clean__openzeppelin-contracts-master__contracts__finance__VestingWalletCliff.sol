


pragma solidity ^0.8.20;

import {SafeCast} from "../utils/math/SafeCast.sol";
import {VestingWallet} from "./VestingWallet.sol";


abstract contract VestingWalletCliff is VestingWallet {
    using SafeCast for *;

    uint64 private immutable _cliff;

    
    error InvalidCliffDuration(uint64 cliffSeconds, uint64 durationSeconds);

    
    constructor(uint64 cliffSeconds) {
        uint256 vestingDuration = duration();
        if (cliffSeconds > vestingDuration) {
            revert InvalidCliffDuration(cliffSeconds, vestingDuration.toUint64());
        }
        _cliff = start().toUint64() + cliffSeconds;
    }

    
    function cliff() public view virtual returns (uint256) {
        return _cliff;
    }

    
    function _vestingSchedule(
        uint256 totalAllocation,
        uint64 timestamp
    ) internal view virtual override returns (uint256) {
        return timestamp < cliff() ? 0 : super._vestingSchedule(totalAllocation, timestamp);
    }
}
