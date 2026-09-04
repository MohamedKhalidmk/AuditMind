
pragma solidity ^0.8.0;


interface IL2Pool {
  
  function supply(bytes32 args) external;

  
  function supplyWithPermit(bytes32 args, bytes32 r, bytes32 s) external;

  
  function withdraw(bytes32 args) external returns (uint256);

  
  function borrow(bytes32 args) external;

  
  function repay(bytes32 args) external returns (uint256);

  
  function repayWithPermit(bytes32 args, bytes32 r, bytes32 s) external returns (uint256);

  
  function repayWithATokens(bytes32 args) external returns (uint256);

  
  function swapBorrowRateMode(bytes32 args) external;

  
  function rebalanceStableBorrowRate(bytes32 args) external;

  
  function setUserUseReserveAsCollateral(bytes32 args) external;

  
  function liquidationCall(bytes32 args1, bytes32 args2) external;
}
