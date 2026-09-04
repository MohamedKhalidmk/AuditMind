
pragma solidity ^0.8.0;

import {CustomRevert} from "./CustomRevert.sol";


library LPFeeLibrary {
    using LPFeeLibrary for uint24;
    using CustomRevert for bytes4;

    
    error LPFeeTooLarge(uint24 fee);

    
    uint24 public constant DYNAMIC_FEE_FLAG = 0x800000;

    
    
    uint24 public constant OVERRIDE_FEE_FLAG = 0x400000;

    
    uint24 public constant REMOVE_OVERRIDE_MASK = 0xBFFFFF;

    
    uint24 public constant MAX_LP_FEE = 1000000;

    
    
    
    function isDynamicFee(uint24 self) internal pure returns (bool) {
        return self == DYNAMIC_FEE_FLAG;
    }

    
    
    
    function isValid(uint24 self) internal pure returns (bool) {
        return self <= MAX_LP_FEE;
    }

    
    
    function validate(uint24 self) internal pure {
        if (!self.isValid()) LPFeeTooLarge.selector.revertWith(self);
    }

    
    
    
    
    function getInitialLPFee(uint24 self) internal pure returns (uint24) {
        
        if (self.isDynamicFee()) return 0;
        self.validate();
        return self;
    }

    
    
    
    function isOverride(uint24 self) internal pure returns (bool) {
        return self & OVERRIDE_FEE_FLAG != 0;
    }

    
    
    
    function removeOverrideFlag(uint24 self) internal pure returns (uint24) {
        return self & REMOVE_OVERRIDE_MASK;
    }

    
    
    
    function removeOverrideFlagAndValidate(uint24 self) internal pure returns (uint24 fee) {
        fee = self.removeOverrideFlag();
        fee.validate();
    }
}
