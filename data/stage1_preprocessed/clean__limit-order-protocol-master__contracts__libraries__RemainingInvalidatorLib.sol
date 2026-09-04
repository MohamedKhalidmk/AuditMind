

pragma solidity ^0.8.0;

type RemainingInvalidator is uint256;


library RemainingInvalidatorLib {

    
    error RemainingInvalidatedOrder();

    
    function isNewOrder(RemainingInvalidator invalidator) internal pure returns(bool) {
        return RemainingInvalidator.unwrap(invalidator) == 0;
    }

    
    function remaining(RemainingInvalidator invalidator) internal pure returns(uint256) {
        uint256 value = RemainingInvalidator.unwrap(invalidator);
        if (value == 0) {
            revert RemainingInvalidatedOrder();
        }
        unchecked {
            return ~value;
        }
    }

    
    function remaining(RemainingInvalidator invalidator, uint256 orderMakerAmount) internal pure returns(uint256) {
        uint256 value = RemainingInvalidator.unwrap(invalidator);
        if (value == 0) {
            return orderMakerAmount;
        }
        unchecked {
            return ~value;
        }
    }

    
    function remains(uint256 remainingMakingAmount, uint256 makingAmount) internal pure returns(RemainingInvalidator) {
        unchecked {
            return RemainingInvalidator.wrap(~(remainingMakingAmount - makingAmount));
        }
    }

    
    function fullyFilled() internal pure returns(RemainingInvalidator) {
        return RemainingInvalidator.wrap(type(uint256).max);
    }
}
