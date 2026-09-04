
pragma solidity ^0.8.10;

import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';
import {IDefaultInterestRateStrategy} from '../interfaces/IDefaultInterestRateStrategy.sol';
import {IReserveInterestRateStrategy} from '../interfaces/IReserveInterestRateStrategy.sol';
import {IPoolAddressesProvider} from '../interfaces/IPoolAddressesProvider.sol';


contract ZeroReserveInterestRateStrategy is IDefaultInterestRateStrategy {
  
  uint256 public constant OPTIMAL_USAGE_RATIO = 0;

  
  uint256 public constant OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO = 0;

  
  uint256 public constant MAX_EXCESS_USAGE_RATIO = 0;

  
  uint256 public constant MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO = 0;

  IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

  
  uint256 internal constant _baseVariableBorrowRate = 0;

  
  uint256 internal constant _variableRateSlope1 = 0;

  
  uint256 internal constant _variableRateSlope2 = 0;

  
  uint256 internal constant _stableRateSlope1 = 0;

  
  uint256 internal constant _stableRateSlope2 = 0;

  
  uint256 internal constant _baseStableRateOffset = 0;

  
  uint256 internal constant _stableRateExcessOffset = 0;

  
  constructor(IPoolAddressesProvider provider) {
    ADDRESSES_PROVIDER = provider;
  }

  
  function getVariableRateSlope1() external pure returns (uint256) {
    return _variableRateSlope1;
  }

  
  function getVariableRateSlope2() external pure returns (uint256) {
    return _variableRateSlope2;
  }

  
  function getStableRateSlope1() external pure returns (uint256) {
    return _stableRateSlope1;
  }

  
  function getStableRateSlope2() external pure returns (uint256) {
    return _stableRateSlope2;
  }

  
  function getStableRateExcessOffset() external pure returns (uint256) {
    return _stableRateExcessOffset;
  }

  
  function getBaseStableBorrowRate() public pure returns (uint256) {
    return _variableRateSlope1 + _baseStableRateOffset;
  }

  
  function getBaseVariableBorrowRate() external pure override returns (uint256) {
    return _baseVariableBorrowRate;
  }

  
  function getMaxVariableBorrowRate() external pure override returns (uint256) {
    return _baseVariableBorrowRate + _variableRateSlope1 + _variableRateSlope2;
  }

  
  function calculateInterestRates(
    DataTypes.CalculateInterestRatesParams memory
  ) public pure override returns (uint256, uint256, uint256) {
    return (0, 0, 0);
  }
}
