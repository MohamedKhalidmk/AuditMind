
pragma solidity ^0.8.10;

import {
    ErrorsAndWarnings,
    ErrorsAndWarningsLib
} from "./ErrorsAndWarnings.sol";

import { IssueParser, MerkleIssue } from "./SeaportValidatorTypes.sol";

contract Murky {
    using ErrorsAndWarningsLib for ErrorsAndWarnings;
    using IssueParser for MerkleIssue;

    bool internal constant HASH_ODD_WITH_ZERO = false;

    function _verifyProof(
        bytes32 root,
        bytes32[] memory proof,
        bytes32 valueToProve
    ) internal pure returns (bool) {
        
        bytes32 rollingHash = valueToProve;
        uint256 length = proof.length;
        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                rollingHash = _hashLeafPairs(rollingHash, proof[i]);
            }
        }
        return root == rollingHash;
    }

    

    
    function _hashLeafPairs(
        bytes32 left,
        bytes32 right
    ) internal pure returns (bytes32 _hash) {
        assembly {
            switch lt(left, right)
            case 0 {
                mstore(0x0, right)
                mstore(0x20, left)
            }
            default {
                mstore(0x0, left)
                mstore(0x20, right)
            }
            _hash := keccak256(0x0, 0x40)
        }
    }

    

    function _getRoot(
        uint256[] memory data
    )
        internal
        pure
        returns (bytes32 result, ErrorsAndWarnings memory errorsAndWarnings)
    {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        if (data.length < 2) {
            errorsAndWarnings.addError(MerkleIssue.SingleLeaf.parseInt());
            return (0, errorsAndWarnings);
        }

        bool hashOddWithZero = HASH_ODD_WITH_ZERO;

        if (!_processInput(data)) {
            errorsAndWarnings.addError(MerkleIssue.Unsorted.parseInt());
            return (0, errorsAndWarnings);
        }

        assembly {
            function hashLeafPairs(left, right) -> _hash {
                switch lt(left, right)
                case 0 {
                    mstore(0x0, right)
                    mstore(0x20, left)
                }
                default {
                    mstore(0x0, left)
                    mstore(0x20, right)
                }
                _hash := keccak256(0x0, 0x40)
            }
            function hashLevel(_data, length, _hashOddWithZero) -> newLength {
                
                let _result := _data
                
                
                
                let oddLength

                
                switch and(length, 1)
                case 1 {
                    
                    newLength := add(1, div(length, 2))
                    oddLength := 1
                }
                default {
                    newLength := div(length, 2)
                }
                
                
                let resultIndexPointer := add(0x20, _data)
                let dataIndexPointer := resultIndexPointer

                
                let stopIteration := add(_data, mul(length, 0x20))
                
                for {

                } lt(dataIndexPointer, stopIteration) {

                } {
                    
                    let data1 := mload(dataIndexPointer)
                    let data2 := mload(add(dataIndexPointer, 0x20))
                    let hashedPair := hashLeafPairs(data1, data2)
                    
                    mstore(resultIndexPointer, hashedPair)
                    
                    resultIndexPointer := add(0x20, resultIndexPointer)
                    
                    dataIndexPointer := add(0x40, dataIndexPointer)
                }
                
                if oddLength {
                    let data1 := mload(dataIndexPointer)
                    let nextValue
                    switch _hashOddWithZero
                    case 0 {
                        nextValue := data1
                    }
                    default {
                        nextValue := hashLeafPairs(data1, 0)
                    }
                    mstore(resultIndexPointer, nextValue)
                }
            }

            let dataLength := mload(data)
            for {

            } gt(dataLength, 1) {

            } {
                dataLength := hashLevel(data, dataLength, hashOddWithZero)
            }
            result := mload(add(0x20, data))
        }
    }

    function _getProof(
        uint256[] memory data,
        uint256 node
    )
        internal
        pure
        returns (
            bytes32[] memory result,
            ErrorsAndWarnings memory errorsAndWarnings
        )
    {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        if (data.length < 2) {
            errorsAndWarnings.addError(MerkleIssue.SingleLeaf.parseInt());
            return (new bytes32[](0), errorsAndWarnings);
        }

        bool hashOddWithZero = HASH_ODD_WITH_ZERO;

        if (!_processInput(data)) {
            errorsAndWarnings.addError(MerkleIssue.Unsorted.parseInt());
            return (new bytes32[](0), errorsAndWarnings);
        }

        
        
        
        
        
        assembly {
            function hashLeafPairs(left, right) -> _hash {
                switch lt(left, right)
                case 0 {
                    mstore(0x0, right)
                    mstore(0x20, left)
                }
                default {
                    mstore(0x0, left)
                    mstore(0x20, right)
                }
                _hash := keccak256(0x0, 0x40)
            }
            function hashLevel(_data, length, _hashOddWithZero) -> newLength {
                
                let _result := _data
                
                
                
                let oddLength

                
                switch and(length, 1)
                case 1 {
                    
                    newLength := add(1, div(length, 2))
                    oddLength := 1
                }
                default {
                    newLength := div(length, 2)
                }
                
                
                let resultIndexPointer := add(0x20, _data)
                let dataIndexPointer := resultIndexPointer

                
                let stopIteration := add(_data, mul(length, 0x20))
                
                for {

                } lt(dataIndexPointer, stopIteration) {

                } {
                    
                    let data1 := mload(dataIndexPointer)
                    let data2 := mload(add(dataIndexPointer, 0x20))
                    let hashedPair := hashLeafPairs(data1, data2)
                    
                    mstore(resultIndexPointer, hashedPair)
                    
                    resultIndexPointer := add(0x20, resultIndexPointer)
                    
                    dataIndexPointer := add(0x40, dataIndexPointer)
                }
                
                if oddLength {
                    let data1 := mload(dataIndexPointer)
                    let nextValue
                    switch _hashOddWithZero
                    case 0 {
                        nextValue := data1
                    }
                    default {
                        nextValue := hashLeafPairs(data1, 0)
                    }
                    mstore(resultIndexPointer, nextValue)
                }
            }

            
            result := mload(0x40)
            
            let resultIndexPtr := add(0x20, result)
            
            let newLength
            
            let dataLength := mload(data)
            for {
                
            } gt(dataLength, 1) {

            } {
                
                let oddNodeIndex := and(node, 1)
                
                let lastNodeIndex := eq(dataLength, add(1, node))
                
                let switchVal := or(shl(1, lastNodeIndex), oddNodeIndex)
                switch switchVal
                
                case 0 {
                    
                    
                    
                    mstore(
                        resultIndexPtr,
                        mload(add(data, mul(0x20, add(2, node))))
                    )
                }
                
                case 2 {
                    
                    mstore(resultIndexPtr, 0)
                }
                
                default {
                    
                    mstore(resultIndexPtr, mload(add(data, mul(0x20, node))))
                }
                
                resultIndexPtr := add(0x20, resultIndexPtr)

                
                node := div(node, 2)
                
                newLength := add(1, newLength)
                
                dataLength := hashLevel(data, dataLength, hashOddWithZero)
            }
            
            mstore(result, newLength)
            
            mstore(0x40, resultIndexPtr)
        }
    }

    
    function _processInput(
        uint256[] memory data
    ) private pure returns (bool sorted) {
        sorted = true;

        
        for (uint256 i = 0; i < data.length; ++i) {
            assembly {
                mstore(
                    add(data, mul(0x20, add(1, i))),
                    keccak256(add(data, mul(0x20, add(1, i))), 0x20)
                )
                
                if and(
                    gt(i, 0),
                    iszero(
                        gt(
                            mload(add(data, mul(0x20, add(1, i)))),
                            mload(add(data, mul(0x20, add(1, sub(i, 1)))))
                        )
                    )
                ) {
                    sorted := 0 
                }
            }
        }
    }

    
    struct HashAndIntTuple {
        uint256 num;
        bytes32 hash;
    }

    function _sortUint256ByHash(
        uint256[] memory values
    ) internal pure returns (uint256[] memory sortedValues) {
        HashAndIntTuple[] memory toSort = new HashAndIntTuple[](values.length);
        for (uint256 i = 0; i < values.length; i++) {
            toSort[i] = HashAndIntTuple(
                values[i],
                keccak256(abi.encode(values[i]))
            );
        }

        _quickSort(toSort, 0, int256(toSort.length - 1));

        sortedValues = new uint256[](values.length);
        for (uint256 i = 0; i < values.length; i++) {
            sortedValues[i] = toSort[i].num;
        }
    }

    function _quickSort(
        HashAndIntTuple[] memory arr,
        int256 left,
        int256 right
    ) internal pure {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        bytes32 pivot = arr[uint256(left + (right - left) / 2)].hash;
        while (i <= j) {
            while (arr[uint256(i)].hash < pivot) i++;
            while (pivot < arr[uint256(j)].hash) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (
                    arr[uint256(j)],
                    arr[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) _quickSort(arr, left, j);
        if (i < right) _quickSort(arr, i, right);
    }
}
