
pragma solidity ^0.8.10;

import {IPool} from '../../interfaces/IPool.sol';
import {IDelegationToken} from '../../interfaces/IDelegationToken.sol';
import {AToken} from './AToken.sol';


contract DelegationAwareAToken is AToken {
  
  event DelegateUnderlyingTo(address indexed delegatee);

  
  constructor(IPool pool) AToken(pool) {
    
  }

  
  function delegateUnderlyingTo(address delegatee) external onlyPoolAdmin {
    IDelegationToken(_underlyingAsset).delegate(delegatee);
    emit DelegateUnderlyingTo(delegatee);
  }
}
