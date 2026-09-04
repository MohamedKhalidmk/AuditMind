


pragma solidity ^0.8.20;

import {NoncesUpgradeable} from "./NoncesUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";


abstract contract NoncesKeyedUpgradeable is Initializable, NoncesUpgradeable {
    
    struct NoncesKeyedStorage {
        mapping(address owner => mapping(uint192 key => uint64)) _nonces;
    }

    
    bytes32 private constant NoncesKeyedStorageLocation = 0x06e302b11020b9cca26edb75da0d4c952e2c49f7ac00d8954230e81bd5769c00;

    function _getNoncesKeyedStorage() private pure returns (NoncesKeyedStorage storage $) {
        assembly {
            $.slot := NoncesKeyedStorageLocation
        }
    }

    function __NoncesKeyed_init() internal onlyInitializing {
    }

    function __NoncesKeyed_init_unchained() internal onlyInitializing {
    }
    
    function nonces(address owner, uint192 key) public view virtual returns (uint256) {
        NoncesKeyedStorage storage $ = _getNoncesKeyedStorage();
        return key == 0 ? nonces(owner) : _pack(key, $._nonces[owner][key]);
    }

    
    function _useNonce(address owner, uint192 key) internal virtual returns (uint256) {
        NoncesKeyedStorage storage $ = _getNoncesKeyedStorage();
        
        
        unchecked {
            
            return key == 0 ? _useNonce(owner) : _pack(key, $._nonces[owner][key]++);
        }
    }

    
    function _useCheckedNonce(address owner, uint256 keyNonce) internal virtual override {
        (uint192 key, ) = _unpack(keyNonce);
        if (key == 0) {
            super._useCheckedNonce(owner, keyNonce);
        } else {
            uint256 current = _useNonce(owner, key);
            if (keyNonce != current) revert InvalidAccountNonce(owner, current);
        }
    }

    
    function _useCheckedNonce(address owner, uint192 key, uint64 nonce) internal virtual {
        _useCheckedNonce(owner, _pack(key, nonce));
    }

    
    function _pack(uint192 key, uint64 nonce) private pure returns (uint256) {
        return (uint256(key) << 64) | nonce;
    }

    
    function _unpack(uint256 keyNonce) private pure returns (uint192 key, uint64 nonce) {
        return (uint192(keyNonce >> 64), uint64(keyNonce));
    }
}
