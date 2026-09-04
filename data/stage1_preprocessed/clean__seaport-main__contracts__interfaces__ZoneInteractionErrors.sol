
pragma solidity ^0.8.13;


interface ZoneInteractionErrors {
    
    error InvalidRestrictedOrder(bytes32 orderHash);

    
    error InvalidContractOrder(bytes32 orderHash);
}
