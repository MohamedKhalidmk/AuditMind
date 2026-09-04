
pragma solidity ^0.8.0;

import {PoolKey} from "./PoolKey.sol";

type PoolId is bytes32;


library PoolIdLibrary {
    
    function toId(PoolKey memory poolKey) internal pure returns (PoolId poolId) {
        assembly ("memory-safe") {
            
            poolId := keccak256(poolKey, 0xa0)
        }
    }
}
