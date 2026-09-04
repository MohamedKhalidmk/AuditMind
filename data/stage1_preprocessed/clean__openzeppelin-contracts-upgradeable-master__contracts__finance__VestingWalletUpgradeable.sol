


pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {OwnableUpgradeable} from "../access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";


contract VestingWalletUpgradeable is Initializable, ContextUpgradeable, OwnableUpgradeable {
    event EtherReleased(uint256 amount);
    event ERC20Released(address indexed token, uint256 amount);

    
    struct VestingWalletStorage {
        uint256 _released;
        mapping(address token => uint256) _erc20Released;
        uint64 _start;
        uint64 _duration;
    }

    
    bytes32 private constant VestingWalletStorageLocation = 0xa1eac494560f7591e4da38ed031587f09556afdfc4399dd2e205b935fdfa3900;

    function _getVestingWalletStorage() private pure returns (VestingWalletStorage storage $) {
        assembly {
            $.slot := VestingWalletStorageLocation
        }
    }

    function initialize(address beneficiary, uint64 startTimestamp, uint64 durationSeconds) public virtual initializer {
        __VestingWallet_init(beneficiary, startTimestamp, durationSeconds);
    }
    
    function __VestingWallet_init(address beneficiary, uint64 startTimestamp, uint64 durationSeconds) internal onlyInitializing {
        __Ownable_init_unchained(beneficiary);
        __VestingWallet_init_unchained(beneficiary, startTimestamp, durationSeconds);
    }

    function __VestingWallet_init_unchained(address, uint64 startTimestamp, uint64 durationSeconds) internal onlyInitializing {
        VestingWalletStorage storage $ = _getVestingWalletStorage();
        $._start = startTimestamp;
        $._duration = durationSeconds;
    }

    
    receive() external payable virtual {}

    
    function start() public view virtual returns (uint256) {
        VestingWalletStorage storage $ = _getVestingWalletStorage();
        return $._start;
    }

    
    function duration() public view virtual returns (uint256) {
        VestingWalletStorage storage $ = _getVestingWalletStorage();
        return $._duration;
    }

    
    function end() public view virtual returns (uint256) {
        return start() + duration();
    }

    
    function released() public view virtual returns (uint256) {
        VestingWalletStorage storage $ = _getVestingWalletStorage();
        return $._released;
    }

    
    function released(address token) public view virtual returns (uint256) {
        VestingWalletStorage storage $ = _getVestingWalletStorage();
        return $._erc20Released[token];
    }

    
    function releasable() public view virtual returns (uint256) {
        return vestedAmount(uint64(block.timestamp)) - released();
    }

    
    function releasable(address token) public view virtual returns (uint256) {
        return vestedAmount(token, uint64(block.timestamp)) - released(token);
    }

    
    function release() public virtual {
        VestingWalletStorage storage $ = _getVestingWalletStorage();
        uint256 amount = releasable();
        $._released += amount;
        emit EtherReleased(amount);
        Address.sendValue(payable(owner()), amount);
    }

    
    function release(address token) public virtual {
        VestingWalletStorage storage $ = _getVestingWalletStorage();
        uint256 amount = releasable(token);
        $._erc20Released[token] += amount;
        emit ERC20Released(token, amount);
        SafeERC20.safeTransfer(IERC20(token), owner(), amount);
    }

    
    function vestedAmount(uint64 timestamp) public view virtual returns (uint256) {
        return _vestingSchedule(address(this).balance + released(), timestamp);
    }

    
    function vestedAmount(address token, uint64 timestamp) public view virtual returns (uint256) {
        return _vestingSchedule(IERC20(token).balanceOf(address(this)) + released(token), timestamp);
    }

    
    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp) internal view virtual returns (uint256) {
        if (timestamp < start()) {
            return 0;
        } else if (timestamp >= end()) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start())) / duration();
        }
    }
}
