


pragma solidity ^0.8.20;

import {ERC20Upgradeable} from "../ERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";


abstract contract ERC20CappedUpgradeable is Initializable, ERC20Upgradeable {
    
    struct ERC20CappedStorage {
        uint256 _cap;
    }

    
    bytes32 private constant ERC20CappedStorageLocation = 0x0f070392f17d5f958cc1ac31867dabecfc5c9758b4a419a200803226d7155d00;

    function _getERC20CappedStorage() private pure returns (ERC20CappedStorage storage $) {
        assembly {
            $.slot := ERC20CappedStorageLocation
        }
    }

    
    error ERC20ExceededCap(uint256 increasedSupply, uint256 cap);

    
    error ERC20InvalidCap(uint256 cap);

    
    function __ERC20Capped_init(uint256 cap_) internal onlyInitializing {
        __ERC20Capped_init_unchained(cap_);
    }

    function __ERC20Capped_init_unchained(uint256 cap_) internal onlyInitializing {
        ERC20CappedStorage storage $ = _getERC20CappedStorage();
        if (cap_ == 0) {
            revert ERC20InvalidCap(0);
        }
        $._cap = cap_;
    }

    
    function cap() public view virtual returns (uint256) {
        ERC20CappedStorage storage $ = _getERC20CappedStorage();
        return $._cap;
    }

    
    function _update(address from, address to, uint256 value) internal virtual override {
        super._update(from, to, value);

        if (from == address(0)) {
            uint256 maxSupply = cap();
            uint256 supply = totalSupply();
            if (supply > maxSupply) {
                revert ERC20ExceededCap(supply, maxSupply);
            }
        }
    }
}
