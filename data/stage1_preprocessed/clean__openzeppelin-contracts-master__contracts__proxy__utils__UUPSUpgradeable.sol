


pragma solidity ^0.8.22;

import {IERC1822Proxiable} from "../../interfaces/draft-IERC1822.sol";
import {ERC1967Utils} from "../ERC1967/ERC1967Utils.sol";


abstract contract UUPSUpgradeable is IERC1822Proxiable {
    
    address private immutable __self = address(this);

    
    string public constant UPGRADE_INTERFACE_VERSION = "5.0.0";

    
    error UUPSUnauthorizedCallContext();

    
    error UUPSUnsupportedProxiableUUID(bytes32 slot);

    
    modifier onlyProxy() {
        _checkProxy();
        _;
    }

    
    modifier notDelegated() {
        _checkNotDelegated();
        _;
    }

    
    function proxiableUUID() external view notDelegated returns (bytes32) {
        return ERC1967Utils.IMPLEMENTATION_SLOT;
    }

    
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data);
    }

    
    function _checkProxy() internal view virtual {
        if (
            address(this) == __self || 
            ERC1967Utils.getImplementation() != __self 
        ) {
            revert UUPSUnauthorizedCallContext();
        }
    }

    
    function _checkNotDelegated() internal view virtual {
        if (address(this) != __self) {
            
            revert UUPSUnauthorizedCallContext();
        }
    }

    
    function _authorizeUpgrade(address newImplementation) internal virtual;

    
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data) private {
        try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
            if (slot != ERC1967Utils.IMPLEMENTATION_SLOT) {
                revert UUPSUnsupportedProxiableUUID(slot);
            }
            ERC1967Utils.upgradeToAndCall(newImplementation, data);
        } catch {
            
            revert ERC1967Utils.ERC1967InvalidImplementation(newImplementation);
        }
    }
}
