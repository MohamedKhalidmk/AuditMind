


pragma solidity ^0.8.26;

import {AbstractSigner} from "./AbstractSigner.sol";
import {SignatureChecker} from "../SignatureChecker.sol";
import {EnumerableSet} from "../../structs/EnumerableSet.sol";


abstract contract MultiSignerERC7913 is AbstractSigner {
    using EnumerableSet for EnumerableSet.BytesSet;
    using SignatureChecker for *;

    EnumerableSet.BytesSet private _signers;
    uint64 private _threshold;

    
    event ERC7913SignerAdded(bytes indexed signers);

    
    event ERC7913SignerRemoved(bytes indexed signers);

    
    event ERC7913ThresholdSet(uint64 threshold);

    
    error MultiSignerERC7913AlreadyExists(bytes signer);

    
    error MultiSignerERC7913NonexistentSigner(bytes signer);

    
    error MultiSignerERC7913InvalidSigner(bytes signer);

    
    error MultiSignerERC7913ZeroThreshold();

    
    error MultiSignerERC7913UnreachableThreshold(uint64 signers, uint64 threshold);

    constructor(bytes[] memory signers_, uint64 threshold_) {
        _addSigners(signers_);
        _setThreshold(threshold_);
    }

    
    function getSigners(uint64 start, uint64 end) public view virtual returns (bytes[] memory) {
        return _signers.values(start, end);
    }

    
    function getSignerCount() public view virtual returns (uint256) {
        return _signers.length();
    }

    
    function isSigner(bytes memory signer) public view virtual returns (bool) {
        return _signers.contains(signer);
    }

    
    function threshold() public view virtual returns (uint64) {
        return _threshold;
    }

    
    function _addSigners(bytes[] memory newSigners) internal virtual {
        for (uint256 i = 0; i < newSigners.length; ++i) {
            bytes memory signer = newSigners[i];
            require(signer.length >= 20, MultiSignerERC7913InvalidSigner(signer));
            require(_signers.add(signer), MultiSignerERC7913AlreadyExists(signer));
            emit ERC7913SignerAdded(signer);
        }
    }

    
    function _removeSigners(bytes[] memory oldSigners) internal virtual {
        for (uint256 i = 0; i < oldSigners.length; ++i) {
            bytes memory signer = oldSigners[i];
            require(_signers.remove(signer), MultiSignerERC7913NonexistentSigner(signer));
            emit ERC7913SignerRemoved(signer);
        }
        _validateReachableThreshold();
    }

    
    function _setThreshold(uint64 newThreshold) internal virtual {
        require(newThreshold > 0, MultiSignerERC7913ZeroThreshold());
        _threshold = newThreshold;
        _validateReachableThreshold();
        emit ERC7913ThresholdSet(newThreshold);
    }

    
    function _validateReachableThreshold() internal view virtual {
        uint256 signersLength = _signers.length();
        uint64 currentThreshold = threshold();
        require(
            signersLength >= currentThreshold,
            MultiSignerERC7913UnreachableThreshold(
                uint64(signersLength), 
                currentThreshold
            )
        );
    }

    
    function _rawSignatureValidation(
        bytes32 hash,
        bytes calldata signature
    ) internal view virtual override returns (bool) {
        if (signature.length == 0) return false; 
        (bool success, bytes[] calldata signers, bytes[] calldata signatures) = _tryDecodeMultisignatureCalldata(
            signature
        );
        return success && _validateThreshold(signers) && _validateSignatures(hash, signers, signatures);
    }

    
    function _validateSignatures(
        bytes32 hash,
        bytes[] calldata signers,
        bytes[] calldata signatures
    ) internal view virtual returns (bool valid) {
        for (uint256 i = 0; i < signers.length; ++i) {
            if (!isSigner(signers[i])) {
                return false;
            }
        }
        return hash.areValidSignaturesNow(signers, signatures);
    }

    
    function _validateThreshold(bytes[] calldata validatingSigners) internal view virtual returns (bool) {
        return validatingSigners.length >= threshold();
    }

    
    function _tryDecodeMultisignatureCalldata(
        bytes calldata signature
    ) private pure returns (bool success, bytes[] calldata signers, bytes[] calldata signatures) {
        unchecked {
            uint256 bufferLength = signature.length;

            
            
            if (bufferLength < 0x40) return (false, _emptyBytesArray(), _emptyBytesArray());

            
            
            uint256 signersOffset;
            uint256 signaturesOffset;
            assembly ("memory-safe") {
                signersOffset := calldataload(signature.offset)
                signaturesOffset := calldataload(add(signature.offset, 0x20))
            }

            
            if (signersOffset > bufferLength - 0x20 || signaturesOffset > bufferLength - 0x20)
                return (false, _emptyBytesArray(), _emptyBytesArray());

            
            
            uint256 signersLength;
            uint256 signaturesLength;
            assembly ("memory-safe") {
                signersLength := calldataload(add(signature.offset, signersOffset))
                signaturesLength := calldataload(add(signature.offset, signaturesOffset))
            }

            
            uint256 signersDataOffset = signersOffset + 0x20;
            uint256 signaturesDataOffset = signaturesOffset + 0x20;

            
            
            
            if (
                signersLength > type(uint64).max ||
                signaturesLength > type(uint64).max ||
                0x20 * signersLength > bufferLength - signersDataOffset ||
                0x20 * signaturesLength > bufferLength - signaturesDataOffset
            ) return (false, _emptyBytesArray(), _emptyBytesArray());

            
            assembly ("memory-safe") {
                success := 1 
                signers.offset := add(signature.offset, signersDataOffset)
                signers.length := signersLength
                signatures.offset := add(signature.offset, signaturesDataOffset)
                signatures.length := signaturesLength
            }
        }
    }

    
    function _emptyBytesArray() private pure returns (bytes[] calldata result) {
        assembly ("memory-safe") {
            result.offset := 0
            result.length := 0
        }
    }
}
