

pragma solidity ^0.8.26;

import {ERC3009} from "./draft-ERC3009.sol";
import {SignatureChecker} from "../../../utils/cryptography/SignatureChecker.sol";
import {NoncesKeyed} from "../../../utils/NoncesKeyed.sol";


abstract contract ERC20TransferAuthorization is ERC3009, NoncesKeyed {
    
    function authorizationState(address authorizer, bytes32 nonce) public view virtual override returns (bool) {
        
        return uint64(nonces(authorizer, uint192(uint256(nonce) >> 64))) > uint64(uint256(nonce));
    }

    
    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        bytes memory signature
    ) public virtual {
        bytes32 hash = _hashTypedDataV4(
            keccak256(abi.encode(TRANSFER_WITH_AUTHORIZATION_TYPEHASH, from, to, value, validAfter, validBefore, nonce))
        );
        require(SignatureChecker.isValidSignatureNow(from, hash, signature), ERC3009InvalidSignature());
        _transferWithAuthorization(from, to, value, validAfter, validBefore, nonce);
    }

    
    function receiveWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        bytes memory signature
    ) public virtual {
        bytes32 hash = _hashTypedDataV4(
            keccak256(abi.encode(RECEIVE_WITH_AUTHORIZATION_TYPEHASH, from, to, value, validAfter, validBefore, nonce))
        );
        require(SignatureChecker.isValidSignatureNow(from, hash, signature), ERC3009InvalidSignature());
        require(to == _msgSender(), ERC20InvalidReceiver(to));
        _transferWithAuthorization(from, to, value, validAfter, validBefore, nonce);
    }

    
    function cancelAuthorization(address authorizer, bytes32 nonce, bytes memory signature) public virtual {
        bytes32 hash = _hashTypedDataV4(keccak256(abi.encode(CANCEL_AUTHORIZATION_TYPEHASH, authorizer, nonce)));
        require(SignatureChecker.isValidSignatureNow(authorizer, hash, signature), ERC3009InvalidSignature());
        _cancelAuthorization(authorizer, nonce);
    }

    
    function _consumeNonce(address authorizer, bytes32 nonce) internal virtual override {
        _useCheckedNonce(authorizer, uint256(nonce));
    }
}
