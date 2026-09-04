
pragma solidity ^0.8.10;

import {IPool} from '../../../interfaces/IPool.sol';
import {IInitializableAToken} from '../../../interfaces/IInitializableAToken.sol';
import {IInitializableDebtToken} from '../../../interfaces/IInitializableDebtToken.sol';
import {InitializableImmutableAdminUpgradeabilityProxy} from '../aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {ConfiguratorInputTypes} from '../types/ConfiguratorInputTypes.sol';


library ConfiguratorLogic {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  
  event ReserveInitialized(
    address indexed asset,
    address indexed aToken,
    address stableDebtToken,
    address variableDebtToken,
    address interestRateStrategyAddress
  );
  event ATokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );
  event StableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );
  event VariableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  
  function executeInitReserve(
    IPool pool,
    ConfiguratorInputTypes.InitReserveInput calldata input
  ) public {
    address aTokenProxyAddress = _initTokenWithProxy(
      input.aTokenImpl,
      abi.encodeWithSelector(
        IInitializableAToken.initialize.selector,
        pool,
        input.treasury,
        input.underlyingAsset,
        input.incentivesController,
        input.underlyingAssetDecimals,
        input.aTokenName,
        input.aTokenSymbol,
        input.params
      )
    );

    address stableDebtTokenProxyAddress = _initTokenWithProxy(
      input.stableDebtTokenImpl,
      abi.encodeWithSelector(
        IInitializableDebtToken.initialize.selector,
        pool,
        input.underlyingAsset,
        input.incentivesController,
        input.underlyingAssetDecimals,
        input.stableDebtTokenName,
        input.stableDebtTokenSymbol,
        input.params
      )
    );

    address variableDebtTokenProxyAddress = _initTokenWithProxy(
      input.variableDebtTokenImpl,
      abi.encodeWithSelector(
        IInitializableDebtToken.initialize.selector,
        pool,
        input.underlyingAsset,
        input.incentivesController,
        input.underlyingAssetDecimals,
        input.variableDebtTokenName,
        input.variableDebtTokenSymbol,
        input.params
      )
    );

    pool.initReserve(
      input.underlyingAsset,
      aTokenProxyAddress,
      stableDebtTokenProxyAddress,
      variableDebtTokenProxyAddress,
      input.interestRateStrategyAddress
    );

    DataTypes.ReserveConfigurationMap memory currentConfig = DataTypes.ReserveConfigurationMap(0);

    currentConfig.setDecimals(input.underlyingAssetDecimals);

    currentConfig.setActive(true);
    currentConfig.setPaused(false);
    currentConfig.setFrozen(false);

    pool.setConfiguration(input.underlyingAsset, currentConfig);

    emit ReserveInitialized(
      input.underlyingAsset,
      aTokenProxyAddress,
      stableDebtTokenProxyAddress,
      variableDebtTokenProxyAddress,
      input.interestRateStrategyAddress
    );
  }

  
  function executeUpdateAToken(
    IPool cachedPool,
    ConfiguratorInputTypes.UpdateATokenInput calldata input
  ) public {
    DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

    (, , , uint256 decimals, , ) = cachedPool.getConfiguration(input.asset).getParams();

    bytes memory encodedCall = abi.encodeWithSelector(
      IInitializableAToken.initialize.selector,
      cachedPool,
      input.treasury,
      input.asset,
      input.incentivesController,
      decimals,
      input.name,
      input.symbol,
      input.params
    );

    _upgradeTokenImplementation(reserveData.aTokenAddress, input.implementation, encodedCall);

    emit ATokenUpgraded(input.asset, reserveData.aTokenAddress, input.implementation);
  }

  
  function executeUpdateStableDebtToken(
    IPool cachedPool,
    ConfiguratorInputTypes.UpdateDebtTokenInput calldata input
  ) public {
    DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

    (, , , uint256 decimals, , ) = cachedPool.getConfiguration(input.asset).getParams();

    bytes memory encodedCall = abi.encodeWithSelector(
      IInitializableDebtToken.initialize.selector,
      cachedPool,
      input.asset,
      input.incentivesController,
      decimals,
      input.name,
      input.symbol,
      input.params
    );

    _upgradeTokenImplementation(
      reserveData.stableDebtTokenAddress,
      input.implementation,
      encodedCall
    );

    emit StableDebtTokenUpgraded(
      input.asset,
      reserveData.stableDebtTokenAddress,
      input.implementation
    );
  }

  
  function executeUpdateVariableDebtToken(
    IPool cachedPool,
    ConfiguratorInputTypes.UpdateDebtTokenInput calldata input
  ) public {
    DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

    (, , , uint256 decimals, , ) = cachedPool.getConfiguration(input.asset).getParams();

    bytes memory encodedCall = abi.encodeWithSelector(
      IInitializableDebtToken.initialize.selector,
      cachedPool,
      input.asset,
      input.incentivesController,
      decimals,
      input.name,
      input.symbol,
      input.params
    );

    _upgradeTokenImplementation(
      reserveData.variableDebtTokenAddress,
      input.implementation,
      encodedCall
    );

    emit VariableDebtTokenUpgraded(
      input.asset,
      reserveData.variableDebtTokenAddress,
      input.implementation
    );
  }

  
  function _initTokenWithProxy(
    address implementation,
    bytes memory initParams
  ) internal returns (address) {
    InitializableImmutableAdminUpgradeabilityProxy proxy = new InitializableImmutableAdminUpgradeabilityProxy(
        address(this)
      );

    proxy.initialize(implementation, initParams);

    return address(proxy);
  }

  
  function _upgradeTokenImplementation(
    address proxyAddress,
    address implementation,
    bytes memory initParams
  ) internal {
    InitializableImmutableAdminUpgradeabilityProxy proxy = InitializableImmutableAdminUpgradeabilityProxy(
        payable(proxyAddress)
      );

    proxy.upgradeToAndCall(implementation, initParams);
  }
}
