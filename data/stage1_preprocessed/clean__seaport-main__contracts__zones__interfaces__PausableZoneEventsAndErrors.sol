
pragma solidity ^0.8.13;


interface PausableZoneEventsAndErrors {
    
    event Paused();

    
    event Unpaused();

    
    event PotentialOwnerUpdated(address newPotentialOwner);

    
    event OwnershipTransferred(address previousOwner, address newOwner);

    
    event ZoneCreated(address zone, bytes32 salt);

    
    event PauserUpdated(address newPauser);

    
    event OperatorUpdated(address newOperator);

    
    error InvalidPauser();

    
    error InvalidOperator();

    
    error InvalidController();
    
    error ZoneAlreadyExists(address zone);

    
    error CallerIsNotOwner();

    
    error CallerIsNotOperator();

    
    error OwnerCanNotBeSetAsZero();

    
    error PauserCanNotBeSetAsZero();

    
    error CallerIsNotPotentialOwner();

    
    error ZoneIsPaused();
}
