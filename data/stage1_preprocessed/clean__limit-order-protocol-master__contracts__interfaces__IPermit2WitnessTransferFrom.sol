

pragma solidity ^0.8.0;

interface IPermit2WitnessTransferFrom {
    struct TokenPermissions {
        
        address token;
        
        uint256 amount;
    }

    struct PermitTransferFrom {
        TokenPermissions permitted;
        
        uint256 nonce;
        
        uint256 deadline;
    }

    struct SignatureTransferDetails {
        
        address to;
        
        uint256 requestedAmount;
    }

    function permitWitnessTransferFrom(
        PermitTransferFrom calldata permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;
}
