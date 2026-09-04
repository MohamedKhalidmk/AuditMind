

pragma solidity ^0.8.0;




library ParseBytes {
    function parseSelector(bytes memory result) internal pure returns (bytes4 selector) {
        
        assembly ("memory-safe") {
            selector := mload(add(result, 0x20))
        }
    }

    function parseFee(bytes memory result) internal pure returns (uint24 lpFee) {
        
        assembly ("memory-safe") {
            lpFee := mload(add(result, 0x60))
        }
    }

    function parseReturnDelta(bytes memory result) internal pure returns (int256 hookReturn) {
        
        assembly ("memory-safe") {
            hookReturn := mload(add(result, 0x40))
        }
    }
}
