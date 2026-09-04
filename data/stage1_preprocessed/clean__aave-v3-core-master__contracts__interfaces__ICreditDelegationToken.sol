
pragma solidity ^0.8.0;


interface ICreditDelegationToken {
  
  event BorrowAllowanceDelegated(
    address indexed fromUser,
    address indexed toUser,
    address indexed asset,
    uint256 amount
  );

  
  function approveDelegation(address delegatee, uint256 amount) external;

  
  function borrowAllowance(address fromUser, address toUser) external view returns (uint256);

  
  function delegationWithSig(
    address delegator,
    address delegatee,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}
