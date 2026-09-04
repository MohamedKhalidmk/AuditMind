


pragma solidity ^0.8.20;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {VestingWalletUpgradeable} from "./VestingWalletUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";


abstract contract VestingWalletCliffUpgradeable is Initializable, VestingWalletUpgradeable {
    using SafeCast for *;

    
    struct VestingWalletCliffStorage {
        uint64 _cliff;
    }

    
    bytes32 private constant VestingWalletCliffStorageLocation = 0x0a0ceb66c7c9aef32c0bfc43d3108868a39e95e96162520745e462557492f100;

    function _getVestingWalletCliffStorage() private pure returns (VestingWalletCliffStorage storage $) {
        assembly {
            $.slot := VestingWalletCliffStorageLocation
        }
    }

    
    error InvalidCliffDuration(uint64 cliffSeconds, uint64 durationSeconds);

    
    function __VestingWalletCliff_init(uint64 cliffSeconds) internal onlyInitializing {
        __VestingWalletCliff_init_unchained(cliffSeconds);
    }

    function __VestingWalletCliff_init_unchained(uint64 cliffSeconds) internal onlyInitializing {
        VestingWalletCliffStorage storage $ = _getVestingWalletCliffStorage();
        uint256 vestingDuration = duration();
        if (cliffSeconds > vestingDuration) {
            revert InvalidCliffDuration(cliffSeconds, vestingDuration.toUint64());
        }
        $._cliff = start().toUint64() + cliffSeconds;
    }

    
    function cliff() public view virtual returns (uint256) {
        VestingWalletCliffStorage storage $ = _getVestingWalletCliffStorage();
        return $._cliff;
    }

    
    function _vestingSchedule(
        uint256 totalAllocation,
        uint64 timestamp
    ) internal view virtual override returns (uint256) {
        return timestamp < cliff() ? 0 : super._vestingSchedule(totalAllocation, timestamp);
    }
}
