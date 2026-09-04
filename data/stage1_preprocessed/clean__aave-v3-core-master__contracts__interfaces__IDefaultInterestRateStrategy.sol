
pragma solidity ^0.8.0;

import {IReserveInterestRateStrategy} from './IReserveInterestRateStrategy.sol';
import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';


interface IDefaultInterestRateStrategy is IReserveInterestRateStrategy {
  
  function OPTIMAL_USAGE_RATIO() external view returns (uint256);

  
  function OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO() external view returns (uint256);

  
  function MAX_EXCESS_USAGE_RATIO() external view returns (uint256);

  
  function MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO() external view returns (uint256);

  
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  
  function getVariableRateSlope1() external view returns (uint256);

  
  function getVariableRateSlope2() external view returns (uint256);

  
  function getStableRateSlope1() external view returns (uint256);

  
  function getStableRateSlope2() external view returns (uint256);

  
  function getStableRateExcessOffset() external view returns (uint256);

  
  function getBaseStableBorrowRate() external view returns (uint256);

  
  function getBaseVariableBorrowRate() external view returns (uint256);

  
  function getMaxVariableBorrowRate() external view returns (uint256);
}
