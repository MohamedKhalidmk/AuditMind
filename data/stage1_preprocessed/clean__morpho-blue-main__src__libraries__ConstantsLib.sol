
pragma solidity ^0.8.0;


uint256 constant MAX_FEE = 0.25e18;


uint256 constant ORACLE_PRICE_SCALE = 1e36;


uint256 constant LIQUIDATION_CURSOR = 0.3e18;


uint256 constant MAX_LIQUIDATION_INCENTIVE_FACTOR = 1.15e18;


bytes32 constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");


bytes32 constant AUTHORIZATION_TYPEHASH =
    keccak256("Authorization(address authorizer,address authorized,bool isAuthorized,uint256 nonce,uint256 deadline)");
