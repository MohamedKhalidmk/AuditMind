
pragma solidity ^0.8.0;

import {CustomRevert} from "./libraries/CustomRevert.sol";



abstract contract NoDelegateCall {
    using CustomRevert for bytes4;

    error DelegateCallNotAllowed();

    
    address private immutable original;

    constructor() {
        
        
        original = address(this);
    }

    
    
    function checkNotDelegateCall() private view {
        if (address(this) != original) DelegateCallNotAllowed.selector.revertWith();
    }

    
    modifier noDelegateCall() {
        checkNotDelegateCall();
        _;
    }
}
