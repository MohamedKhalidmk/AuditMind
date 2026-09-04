


pragma solidity ^0.8.20;

import {ERC20Upgradeable} from "../ERC20Upgradeable.sol";
import {PausableUpgradeable} from "../../../utils/PausableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";


abstract contract ERC20PausableUpgradeable is Initializable, ERC20Upgradeable, PausableUpgradeable {
    function __ERC20Pausable_init() internal onlyInitializing {
    }

    function __ERC20Pausable_init_unchained() internal onlyInitializing {
    }
    
    function _update(address from, address to, uint256 value) internal virtual override whenNotPaused {
        super._update(from, to, value);
    }
}
