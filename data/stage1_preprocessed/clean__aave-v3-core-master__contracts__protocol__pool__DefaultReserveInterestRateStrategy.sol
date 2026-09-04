
pragma solidity ^0.8.10;

import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {WadRayMath} from '../libraries/math/WadRayMath.sol';
import {PercentageMath} from '../libraries/math/PercentageMath.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';
import {Errors} from '../libraries/helpers/Errors.sol';
import {IDefaultInterestRateStrategy} from '../../interfaces/IDefaultInterestRateStrategy.sol';
import {IReserveInterestRateStrategy} from '../../interfaces/IReserveInterestRateStrategy.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';


contract DefaultReserveInterestRateStrategy is IDefaultInterestRateStrategy {
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  
  uint256 public immutable OPTIMAL_USAGE_RATIO;

  
  uint256 public immutable OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO;

  
  uint256 public immutable MAX_EXCESS_USAGE_RATIO;

  
  uint256 public immutable MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO;

  IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

  
  uint256 internal immutable _baseVariableBorrowRate;

  
  uint256 internal immutable _variableRateSlope1;

  
  uint256 internal immutable _variableRateSlope2;

  
  uint256 internal immutable _stableRateSlope1;

  
  uint256 internal immutable _stableRateSlope2;

  
  uint256 internal immutable _baseStableRateOffset;

  
  uint256 internal immutable _stableRateExcessOffset;

  
  constructor(
    IPoolAddressesProvider provider,
    uint256 optimalUsageRatio,
    uint256 baseVariableBorrowRate,
    uint256 variableRateSlope1,
    uint256 variableRateSlope2,
    uint256 stableRateSlope1,
    uint256 stableRateSlope2,
    uint256 baseStableRateOffset,
    uint256 stableRateExcessOffset,
    uint256 optimalStableToTotalDebtRatio
  ) {
    require(WadRayMath.RAY >= optimalUsageRatio, Errors.INVALID_OPTIMAL_USAGE_RATIO);
    require(
      WadRayMath.RAY >= optimalStableToTotalDebtRatio,
      Errors.INVALID_OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO
    );
    OPTIMAL_USAGE_RATIO = optimalUsageRatio;
    MAX_EXCESS_USAGE_RATIO = WadRayMath.RAY - optimalUsageRatio;
    OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO = optimalStableToTotalDebtRatio;
    MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO = WadRayMath.RAY - optimalStableToTotalDebtRatio;
    ADDRESSES_PROVIDER = provider;
    _baseVariableBorrowRate = baseVariableBorrowRate;
    _variableRateSlope1 = variableRateSlope1;
    _variableRateSlope2 = variableRateSlope2;
    _stableRateSlope1 = stableRateSlope1;
    _stableRateSlope2 = stableRateSlope2;
    _baseStableRateOffset = baseStableRateOffset;
    _stableRateExcessOffset = stableRateExcessOffset;
  }

  
  function getVariableRateSlope1() external view returns (uint256) {
    return _variableRateSlope1;
  }

  
  function getVariableRateSlope2() external view returns (uint256) {
    return _variableRateSlope2;
  }

  
  function getStableRateSlope1() external view returns (uint256) {
    return _stableRateSlope1;
  }

  
  function getStableRateSlope2() external view returns (uint256) {
    return _stableRateSlope2;
  }

  
  function getStableRateExcessOffset() external view returns (uint256) {
    return _stableRateExcessOffset;
  }

  
  function getBaseStableBorrowRate() public view returns (uint256) {
    return _variableRateSlope1 + _baseStableRateOffset;
  }

  
  function getBaseVariableBorrowRate() external view override returns (uint256) {
    return _baseVariableBorrowRate;
  }

  
  function getMaxVariableBorrowRate() external view override returns (uint256) {
    return _baseVariableBorrowRate + _variableRateSlope1 + _variableRateSlope2;
  }

  struct CalcInterestRatesLocalVars {
    uint256 availableLiquidity;
    uint256 totalDebt;
    uint256 currentVariableBorrowRate;
    uint256 currentStableBorrowRate;
    uint256 currentLiquidityRate;
    uint256 borrowUsageRatio;
    uint256 supplyUsageRatio;
    uint256 stableToTotalDebtRatio;
    uint256 availableLiquidityPlusDebt;
  }

  
  function calculateInterestRates(
    DataTypes.CalculateInterestRatesParams memory params
  ) public view override returns (uint256, uint256, uint256) {
    CalcInterestRatesLocalVars memory vars;

    vars.totalDebt = params.totalStableDebt + params.totalVariableDebt;

    vars.currentLiquidityRate = 0;
    vars.currentVariableBorrowRate = _baseVariableBorrowRate;
    vars.currentStableBorrowRate = getBaseStableBorrowRate();

    if (vars.totalDebt != 0) {
      vars.stableToTotalDebtRatio = params.totalStableDebt.rayDiv(vars.totalDebt);
      vars.availableLiquidity =
        IERC20(params.reserve).balanceOf(params.aToken) +
        params.liquidityAdded -
        params.liquidityTaken;

      vars.availableLiquidityPlusDebt = vars.availableLiquidity + vars.totalDebt;
      vars.borrowUsageRatio = vars.totalDebt.rayDiv(vars.availableLiquidityPlusDebt);
      vars.supplyUsageRatio = vars.totalDebt.rayDiv(
        vars.availableLiquidityPlusDebt + params.unbacked
      );
    }

    if (vars.borrowUsageRatio > OPTIMAL_USAGE_RATIO) {
      uint256 excessBorrowUsageRatio = (vars.borrowUsageRatio - OPTIMAL_USAGE_RATIO).rayDiv(
        MAX_EXCESS_USAGE_RATIO
      );

      vars.currentStableBorrowRate +=
        _stableRateSlope1 +
        _stableRateSlope2.rayMul(excessBorrowUsageRatio);

      vars.currentVariableBorrowRate +=
        _variableRateSlope1 +
        _variableRateSlope2.rayMul(excessBorrowUsageRatio);
    } else {
      vars.currentStableBorrowRate += _stableRateSlope1.rayMul(vars.borrowUsageRatio).rayDiv(
        OPTIMAL_USAGE_RATIO
      );

      vars.currentVariableBorrowRate += _variableRateSlope1.rayMul(vars.borrowUsageRatio).rayDiv(
        OPTIMAL_USAGE_RATIO
      );
    }

    if (vars.stableToTotalDebtRatio > OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO) {
      uint256 excessStableDebtRatio = (vars.stableToTotalDebtRatio -
        OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO).rayDiv(MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO);
      vars.currentStableBorrowRate += _stableRateExcessOffset.rayMul(excessStableDebtRatio);
    }

    vars.currentLiquidityRate = _getOverallBorrowRate(
      params.totalStableDebt,
      params.totalVariableDebt,
      vars.currentVariableBorrowRate,
      params.averageStableBorrowRate
    ).rayMul(vars.supplyUsageRatio).percentMul(
        PercentageMath.PERCENTAGE_FACTOR - params.reserveFactor
      );

    return (
      vars.currentLiquidityRate,
      vars.currentStableBorrowRate,
      vars.currentVariableBorrowRate
    );
  }

  
  function _getOverallBorrowRate(
    uint256 totalStableDebt,
    uint256 totalVariableDebt,
    uint256 currentVariableBorrowRate,
    uint256 currentAverageStableBorrowRate
  ) internal pure returns (uint256) {
    uint256 totalDebt = totalStableDebt + totalVariableDebt;

    if (totalDebt == 0) return 0;

    uint256 weightedVariableRate = totalVariableDebt.wadToRay().rayMul(currentVariableBorrowRate);

    uint256 weightedStableRate = totalStableDebt.wadToRay().rayMul(currentAverageStableBorrowRate);

    uint256 overallBorrowRate = (weightedVariableRate + weightedStableRate).rayDiv(
      totalDebt.wadToRay()
    );

    return overallBorrowRate;
  }
}
