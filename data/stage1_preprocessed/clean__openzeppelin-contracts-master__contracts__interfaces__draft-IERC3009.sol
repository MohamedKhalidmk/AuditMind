


pragma solidity >=0.4.16;


interface IERC3009 {
    
    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);

    
    function authorizationState(address authorizer, bytes32 nonce) external view returns (bool);

    
    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    
    function receiveWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}


interface IERC3009Cancel {
    
    event AuthorizationCanceled(address indexed authorizer, bytes32 indexed nonce);

    
    function cancelAuthorization(address authorizer, bytes32 nonce, uint8 v, bytes32 r, bytes32 s) external;
}
