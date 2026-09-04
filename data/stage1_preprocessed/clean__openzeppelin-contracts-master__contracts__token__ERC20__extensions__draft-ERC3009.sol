

pragma solidity ^0.8.26;

import {ERC20} from "../ERC20.sol";
import {EIP712} from "../../../utils/cryptography/EIP712.sol";
import {ECDSA} from "../../../utils/cryptography/ECDSA.sol";
import {IERC3009, IERC3009Cancel} from "../../../interfaces/draft-IERC3009.sol";
import {Time} from "../../../utils/types/Time.sol";
import {ERC4337Utils} from "../../../account/utils/ERC4337Utils.sol";


abstract contract ERC3009 is ERC20, EIP712, IERC3009, IERC3009Cancel {
    
    error ERC3009InvalidSignature();

    
    error ERC3009InvalidAuthorizationTime(uint256 validAfter, uint256 validBefore);

    
    error ERC3009UsedAuthorization(address authorizer, bytes32 nonce);

    bytes32 internal constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
        keccak256(
            "TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)"
        );
    bytes32 internal constant RECEIVE_WITH_AUTHORIZATION_TYPEHASH =
        keccak256(
            "ReceiveWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)"
        );
    bytes32 internal constant CANCEL_AUTHORIZATION_TYPEHASH =
        keccak256("CancelAuthorization(address authorizer,bytes32 nonce)");

    mapping(address account => mapping(bytes32 nonce => bool used)) private _usedNonces;

    
    function authorizationState(address authorizer, bytes32 nonce) public view virtual returns (bool) {
        return _usedNonces[authorizer][nonce];
    }

    
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
    ) public virtual {
        bytes32 hash = _hashTypedDataV4(
            keccak256(abi.encode(TRANSFER_WITH_AUTHORIZATION_TYPEHASH, from, to, value, validAfter, validBefore, nonce))
        );
        require(from == ECDSA.recover(hash, v, r, s), ERC3009InvalidSignature());
        _transferWithAuthorization(from, to, value, validAfter, validBefore, nonce);
    }

    
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
    ) public virtual {
        bytes32 hash = _hashTypedDataV4(
            keccak256(abi.encode(RECEIVE_WITH_AUTHORIZATION_TYPEHASH, from, to, value, validAfter, validBefore, nonce))
        );
        require(from == ECDSA.recover(hash, v, r, s), ERC3009InvalidSignature());
        require(to == _msgSender(), ERC20InvalidReceiver(to));
        _transferWithAuthorization(from, to, value, validAfter, validBefore, nonce);
    }

    
    function cancelAuthorization(address authorizer, bytes32 nonce, uint8 v, bytes32 r, bytes32 s) public virtual {
        bytes32 hash = _hashTypedDataV4(keccak256(abi.encode(CANCEL_AUTHORIZATION_TYPEHASH, authorizer, nonce)));
        require(authorizer == ECDSA.recover(hash, v, r, s), ERC3009InvalidSignature());
        _cancelAuthorization(authorizer, nonce);
    }

    
    function _transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce
    ) internal virtual {
        _checkValidity(validAfter, validBefore);
        _consumeNonce(from, nonce);
        emit AuthorizationUsed(from, nonce);
        _transfer(from, to, value);
    }

    
    function _cancelAuthorization(address authorizer, bytes32 nonce) internal virtual {
        _consumeNonce(authorizer, nonce);
        emit AuthorizationCanceled(authorizer, nonce);
    }

    
    function _consumeNonce(address authorizer, bytes32 nonce) internal virtual {
        require(!_usedNonces[authorizer][nonce], ERC3009UsedAuthorization(authorizer, nonce));
        _usedNonces[authorizer][nonce] = true;
    }

    
    function _checkValidity(uint256 validAfter, uint256 validBefore) internal view virtual {
        uint256 flag = validAfter & validBefore & ERC4337Utils.BLOCK_RANGE_FLAG;
        uint256 current = flag == 0 ? Time.timestamp() : Time.blockNumber();
        require(
            current > (validAfter & ~flag) && current < (validBefore & ~flag),
            ERC3009InvalidAuthorizationTime(validAfter, validBefore)
        );
    }
}
