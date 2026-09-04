
pragma solidity >=0.5.0;

import {MarketParams, Market} from "./IMorpho.sol";





interface IIrm {
    
    
    function borrowRate(MarketParams memory marketParams, Market memory market) external returns (uint256);

    
    
    
    function borrowRateView(MarketParams memory marketParams, Market memory market) external view returns (uint256);
}
