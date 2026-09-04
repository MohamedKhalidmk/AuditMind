


pragma solidity ^0.8.20;
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";


abstract contract NoncesUpgradeable is Initializable {
    
    error InvalidAccountNonce(address account, uint256 currentNonce);

    
    struct NoncesStorage {
        mapping(address account => uint256) _nonces;
    }

    
    bytes32 private constant NoncesStorageLocation = 0x5ab42ced628888259c08ac98db1eb0cf702fc1501344311d8b100cd1bfe4bb00;

    function _getNoncesStorage() private pure returns (NoncesStorage storage $) {
        assembly {
            $.slot := NoncesStorageLocation
        }
    }

    function __Nonces_init() internal onlyInitializing {
    }

    function __Nonces_init_unchained() internal onlyInitializing {
    }
    
    function nonces(address owner) public view virtual returns (uint256) {
        NoncesStorage storage $ = _getNoncesStorage();
        return $._nonces[owner];
    }

    
    function _useNonce(address owner) internal virtual returns (uint256) {
        NoncesStorage storage $ = _getNoncesStorage();
        
        
        unchecked {
            
            return $._nonces[owner]++;
        }
    }

    
    function _useCheckedNonce(address owner, uint256 nonce) internal virtual {
        uint256 current = _useNonce(owner);
        if (nonce != current) {
            revert InvalidAccountNonce(owner, current);
        }
    }
}
