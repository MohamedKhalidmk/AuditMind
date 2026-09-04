


pragma solidity ^0.8.24;

import {ERC4337Utils, PackedUserOperation} from "../../utils/ERC4337Utils.sol";
import {EIP7702Utils} from "../../utils/EIP7702Utils.sol";
import {AbstractSigner} from "../../../utils/cryptography/signers/AbstractSigner.sol";
import {EIP712} from "../../../utils/cryptography/EIP712.sol";
import {Paymaster} from "../Paymaster.sol";
import {Bytes} from "../../../utils/Bytes.sol";
import {Calldata} from "../../../utils/Calldata.sol";
import {Memory} from "../../../utils/Memory.sol";


abstract contract PaymasterSigner is AbstractSigner, EIP712, Paymaster {
    using ERC4337Utils for *;

    bytes32 private constant USER_OPERATION_REQUEST_TYPEHASH =
        keccak256(
            "UserOperationRequest(address sender,uint256 nonce,bytes initCode,bytes callData,bytes32 accountGasLimits,uint256 preVerificationGas,bytes32 gasFees,uint256 paymasterVerificationGasLimit,uint256 paymasterPostOpGasLimit,uint48 validAfter,uint48 validUntil)"
        );

    
    function _signableUserOpHash(
        PackedUserOperation calldata userOp,
        uint48 validAfter,
        uint48 validUntil
    ) internal view virtual returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        USER_OPERATION_REQUEST_TYPEHASH,
                        userOp.sender,
                        userOp.nonce,
                        _effectiveInitCodeHash(userOp),
                        keccak256(userOp.callData),
                        userOp.accountGasLimits,
                        userOp.preVerificationGas,
                        userOp.gasFees,
                        userOp.paymasterVerificationGasLimit(),
                        userOp.paymasterPostOpGasLimit(),
                        validAfter,
                        validUntil
                    )
                )
            );
    }

    
    function _effectiveInitCodeHash(PackedUserOperation calldata userOp) private view returns (bytes32) {
        
        
        Memory.Pointer fmp = Memory.getFreeMemoryPointer();

        
        
        bytes memory initCode = userOp.initCode;
        if (bytes20(initCode) == bytes20(bytes2(0x7702))) {
            bytes memory delegate = abi.encodePacked(EIP7702Utils.fetchDelegate(userOp.sender));
            initCode = initCode.length > 20 ? Bytes.replace(initCode, 0, delegate) : delegate;
        }
        bytes32 initCodeHash = keccak256(initCode);

        Memory.unsafeSetFreeMemoryPointer(fmp);
        return initCodeHash;
    }

    
    function _validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 ,
        uint256 
    ) internal virtual override returns (bytes memory context, uint256 validationData) {
        (uint48 validAfter, uint48 validUntil, bytes calldata signature) = _decodePaymasterUserOp(userOp);

        
        bool rangeFlagsCompatible = validUntil == 0 || ((validAfter ^ validUntil) & ERC4337Utils.BLOCK_RANGE_FLAG == 0);

        return (
            bytes(""),
            rangeFlagsCompatible
                ? _rawSignatureValidation(_signableUserOpHash(userOp, validAfter, validUntil), signature)
                    .packValidationData(validAfter, validUntil)
                : ERC4337Utils.SIG_VALIDATION_FAILED
        );
    }

    
    function _decodePaymasterUserOp(
        PackedUserOperation calldata userOp
    ) internal pure virtual returns (uint48 validAfter, uint48 validUntil, bytes calldata signature) {
        bytes calldata paymasterData = userOp.paymasterData();
        return
            paymasterData.length < 12
                ? (uint48(0), uint48(0), Calldata.emptyBytes())
                : (uint48(bytes6(paymasterData[0:6])), uint48(bytes6(paymasterData[6:12])), paymasterData[12:]);
    }
}
