

pragma solidity ^0.8.27;

import {Math} from "./math/Math.sol";
import {SafeCast} from "./math/SafeCast.sol";
import {Checkpoints} from "./structs/Checkpoints.sol";
import {Time} from "./types/Time.sol";


library RateLimiter {
    using Checkpoints for Checkpoints.Trace208;

    
    error RateLimitExceeded();

    
    
    struct RefillingBucketItem {
        uint208 _lastUsed;
        uint48 _lastTimepoint;
    }

    
    struct RefillingBucket {
        uint208 _capacity;
        uint48 _window;
        mapping(bytes32 key => RefillingBucketItem) _items;
    }

    
    function state(
        RefillingBucket storage self,
        bytes32 key
    ) internal view returns (uint256 used_, uint256 available_) {
        uint208 capacity_ = self._capacity; 
        RefillingBucketItem storage item_ = self._items[key]; 

        used_ = Math.saturatingSub(
            item_._lastUsed,
            Math.mulDiv(Time.timestamp() - item_._lastTimepoint, capacity_, Math.max(self._window, 1))
        );
        available_ = Math.saturatingSub(capacity_, used_);
    }

    
    function used(RefillingBucket storage self, bytes32 key) internal view returns (uint256 used_) {
        (used_, ) = state(self, key);
    }

    
    function available(RefillingBucket storage self, bytes32 key) internal view returns (uint256 available_) {
        (, available_) = state(self, key);
    }

    
    function tryConsume(RefillingBucket storage self, bytes32 key, uint256 quantity) internal returns (bool) {
        if (quantity == 0) {
            return true;
        }
        (uint256 used_, uint256 available_) = state(self, key);
        if (quantity <= available_) {
            self._items[key] = RefillingBucketItem({
                _lastTimepoint: Time.timestamp(),
                _lastUsed: SafeCast.toUint208(used_ + quantity)
            });
            return true;
        } else {
            return false;
        }
    }

    
    function consume(RefillingBucket storage self, bytes32 key, uint256 quantity) internal {
        require(tryConsume(self, key, quantity), RateLimitExceeded());
    }

    
    function reset(RefillingBucket storage self, bytes32 key) internal {
        delete self._items[key];
    }

    
    function updateSettings(RefillingBucket storage self, uint48 newWindow, uint208 newCapacity) internal {
        self._capacity = newCapacity;
        self._window = newWindow;
    }

    
    function sync(RefillingBucket storage self, bytes32 key) internal {
        self._items[key] = RefillingBucketItem({_lastTimepoint: Time.timestamp(), _lastUsed: uint208(used(self, key))});
    }

    
    
    struct SlidingWindow {
        uint208 _limit;
        uint48 _window;
        mapping(bytes32 key => Checkpoints.Trace208) _items;
    }

    
    function state(SlidingWindow storage self, bytes32 key) internal view returns (uint256 used_, uint256 available_) {
        Checkpoints.Trace208 storage item_ = self._items[key]; 

        used_ = Math.saturatingSub(
            item_.latest(),
            item_.upperLookupRecent(uint48(Math.saturatingSub(Time.timestamp(), Math.max(self._window, 1))))
        );
        available_ = Math.saturatingSub(self._limit, used_);
    }

    
    function used(SlidingWindow storage self, bytes32 key) internal view returns (uint256 used_) {
        (used_, ) = state(self, key);
    }

    
    function available(SlidingWindow storage self, bytes32 key) internal view returns (uint256 available_) {
        (, available_) = state(self, key);
    }

    
    function tryConsume(SlidingWindow storage self, bytes32 key, uint256 quantity) internal returns (bool) {
        if (quantity == 0) {
            return true;
        }
        (uint256 used_, uint256 available_) = state(self, key);
        if (quantity <= available_) {
            if (used_ == 0) {
                reset(self, key);
            }
            Checkpoints.Trace208 storage item_ = self._items[key]; 
            item_.push(Time.timestamp(), SafeCast.toUint208(item_.latest() + quantity));
            return true;
        } else {
            return false;
        }
    }

    
    function consume(SlidingWindow storage self, bytes32 key, uint256 quantity) internal {
        require(tryConsume(self, key, quantity), RateLimitExceeded());
    }

    
    function reset(SlidingWindow storage self, bytes32 key) internal {
        Checkpoints.Checkpoint208[] storage trace = self._items[key]._checkpoints;
        assembly ("memory-safe") {
            sstore(trace.slot, 0)
        }
    }

    
    function updateSettings(SlidingWindow storage self, uint48 newWindow, uint208 newLimit) internal {
        self._limit = newLimit;
        self._window = newWindow;
    }
}
