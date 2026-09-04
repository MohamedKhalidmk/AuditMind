


pragma solidity ^0.8.26;

import {Create2} from "../../utils/Create2.sol";
import {Errors} from "../../utils/Errors.sol";
import {ERC1967Utils} from "./ERC1967Utils.sol";
import {IERC1967} from "../../interfaces/IERC1967.sol";


library ERC1967Clones {
    

    
    function clone(address implementation) internal returns (address) {
        return clone(implementation, 0);
    }

    
    function clone(address implementation, uint256 value) internal returns (address instance) {
        require(address(this).balance >= value, Errors.InsufficientBalance(address(this).balance, value));
        bytes32 implementationSlot = ERC1967Utils.IMPLEMENTATION_SLOT;
        bytes32 topic1 = IERC1967.Upgraded.selector;
        assembly ("memory-safe") {
            
            let ptr := mload(0x40)
            mstore(add(ptr, 0x78), 0x545af43d5f5f3e6036573d5ffd5b3d5ff3)
            mstore(add(ptr, 0x67), implementationSlot)
            mstore(add(ptr, 0x47), 0x5f5fa260095155f3365f5f375f5f365f7f)
            mstore(add(ptr, 0x36), topic1)
            mstore(add(ptr, 0x16), 0x807f)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x603a5f8160475f3973)

            
            instance := create(value, add(ptr, 0x17), 0x81)
        }

        
        require(instance != address(0), Errors.FailedDeployment());
    }

    
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address) {
        return cloneDeterministic(implementation, salt, 0);
    }

    
    function cloneDeterministic(
        address implementation,
        bytes32 salt,
        uint256 value
    ) internal returns (address instance) {
        require(address(this).balance >= value, Errors.InsufficientBalance(address(this).balance, value));
        bytes32 implementationSlot = ERC1967Utils.IMPLEMENTATION_SLOT;
        bytes32 topic1 = IERC1967.Upgraded.selector;
        assembly ("memory-safe") {
            
            let ptr := mload(0x40)
            mstore(add(ptr, 0x78), 0x545af43d5f5f3e6036573d5ffd5b3d5ff3)
            mstore(add(ptr, 0x67), implementationSlot)
            mstore(add(ptr, 0x47), 0x5f5fa260095155f3365f5f375f5f365f7f)
            mstore(add(ptr, 0x36), topic1)
            mstore(add(ptr, 0x16), 0x807f)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x603a5f8160475f3973)

            
            instance := create2(value, add(ptr, 0x17), 0x81, salt)
        }
        require(instance != address(0), Errors.FailedDeployment());
    }

    
    function predictDeterministicAddress(address implementation, bytes32 salt) internal view returns (address) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }

    
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address) {
        return Create2.computeAddress(salt, _getCloneHash(implementation), deployer);
    }

    function _getCloneHash(address implementation) private pure returns (bytes32 bytecodeHash) {
        bytes32 implementationSlot = ERC1967Utils.IMPLEMENTATION_SLOT;
        bytes32 topic1 = IERC1967.Upgraded.selector;
        assembly ("memory-safe") {
            
            let ptr := mload(0x40)
            mstore(add(ptr, 0x78), 0x545af43d5f5f3e6036573d5ffd5b3d5ff3)
            mstore(add(ptr, 0x67), implementationSlot)
            mstore(add(ptr, 0x47), 0x5f5fa260095155f3365f5f375f5f365f7f)
            mstore(add(ptr, 0x36), topic1)
            mstore(add(ptr, 0x16), 0x807f)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x603a5f8160475f3973)

            
            bytecodeHash := keccak256(add(ptr, 0x17), 0x81)
        }
    }
}
