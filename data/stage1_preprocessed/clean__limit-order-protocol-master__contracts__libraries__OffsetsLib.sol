

pragma solidity ^0.8.0;

type Offsets is uint256;



library OffsetsLib {

    
    error OffsetOutOfBounds();

    
    function get(Offsets offsets, bytes calldata concat, uint256 index) internal pure returns(bytes calldata result) {
        bytes4 exception = OffsetOutOfBounds.selector;
        assembly ("memory-safe") {  
            let bitShift := shl(5, index)                                   
            let begin := and(0xffffffff, shr(bitShift, shl(32, offsets)))   
            let end := and(0xffffffff, shr(bitShift, offsets))              
            result.offset := add(concat.offset, begin)
            result.length := sub(end, begin)
            if gt(end, concat.length) {
                mstore(0, exception)
                revert(0, 4)
            }
        }
    }
}
