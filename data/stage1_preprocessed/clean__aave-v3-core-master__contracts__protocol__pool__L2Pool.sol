
pragma solidity ^0.8.10;

import {Pool} from './Pool.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {IL2Pool} from '../../interfaces/IL2Pool.sol';
import {CalldataLogic} from '../libraries/logic/CalldataLogic.sol';


contract L2Pool is Pool, IL2Pool {
  
  constructor(IPoolAddressesProvider provider) Pool(provider) {
    
  }

  
  function supply(bytes32 args) external override {
    (address asset, uint256 amount, uint16 referralCode) = CalldataLogic.decodeSupplyParams(
      _reservesList,
      args
    );

    supply(asset, amount, msg.sender, referralCode);
  }

  
  function supplyWithPermit(bytes32 args, bytes32 r, bytes32 s) external override {
    (address asset, uint256 amount, uint16 referralCode, uint256 deadline, uint8 v) = CalldataLogic
      .decodeSupplyWithPermitParams(_reservesList, args);

    supplyWithPermit(asset, amount, msg.sender, referralCode, deadline, v, r, s);
  }

  
  function withdraw(bytes32 args) external override returns (uint256) {
    (address asset, uint256 amount) = CalldataLogic.decodeWithdrawParams(_reservesList, args);

    return withdraw(asset, amount, msg.sender);
  }

  
  function borrow(bytes32 args) external override {
    (address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode) = CalldataLogic
      .decodeBorrowParams(_reservesList, args);

    borrow(asset, amount, interestRateMode, referralCode, msg.sender);
  }

  
  function repay(bytes32 args) external override returns (uint256) {
    (address asset, uint256 amount, uint256 interestRateMode) = CalldataLogic.decodeRepayParams(
      _reservesList,
      args
    );

    return repay(asset, amount, interestRateMode, msg.sender);
  }

  
  function repayWithPermit(bytes32 args, bytes32 r, bytes32 s) external override returns (uint256) {
    (
      address asset,
      uint256 amount,
      uint256 interestRateMode,
      uint256 deadline,
      uint8 v
    ) = CalldataLogic.decodeRepayWithPermitParams(_reservesList, args);

    return repayWithPermit(asset, amount, interestRateMode, msg.sender, deadline, v, r, s);
  }

  
  function repayWithATokens(bytes32 args) external override returns (uint256) {
    (address asset, uint256 amount, uint256 interestRateMode) = CalldataLogic.decodeRepayParams(
      _reservesList,
      args
    );

    return repayWithATokens(asset, amount, interestRateMode);
  }

  
  function swapBorrowRateMode(bytes32 args) external override {
    (address asset, uint256 interestRateMode) = CalldataLogic.decodeSwapBorrowRateModeParams(
      _reservesList,
      args
    );
    swapBorrowRateMode(asset, interestRateMode);
  }

  
  function rebalanceStableBorrowRate(bytes32 args) external override {
    (address asset, address user) = CalldataLogic.decodeRebalanceStableBorrowRateParams(
      _reservesList,
      args
    );
    rebalanceStableBorrowRate(asset, user);
  }

  
  function setUserUseReserveAsCollateral(bytes32 args) external override {
    (address asset, bool useAsCollateral) = CalldataLogic.decodeSetUserUseReserveAsCollateralParams(
      _reservesList,
      args
    );
    setUserUseReserveAsCollateral(asset, useAsCollateral);
  }

  
  function liquidationCall(bytes32 args1, bytes32 args2) external override {
    (
      address collateralAsset,
      address debtAsset,
      address user,
      uint256 debtToCover,
      bool receiveAToken
    ) = CalldataLogic.decodeLiquidationCallParams(_reservesList, args1, args2);
    liquidationCall(collateralAsset, debtAsset, user, debtToCover, receiveAToken);
  }
}
