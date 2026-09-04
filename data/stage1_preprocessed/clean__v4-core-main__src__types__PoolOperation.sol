
pragma solidity ^0.8.24;

import {PoolKey} from "../types/PoolKey.sol";
import {BalanceDelta} from "../types/BalanceDelta.sol";


struct ModifyLiquidityParams {
    
    int24 tickLower;
    int24 tickUpper;
    
    int256 liquidityDelta;
    
    bytes32 salt;
}


struct SwapParams {
    
    bool zeroForOne;
    
    int256 amountSpecified;
    
    uint160 sqrtPriceLimitX96;
}
