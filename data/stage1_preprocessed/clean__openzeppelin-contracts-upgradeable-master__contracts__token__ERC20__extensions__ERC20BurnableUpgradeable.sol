


pragma solidity ^0.8.20;

import {ERC20Upgradeable} from "../ERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";


abstract contract ERC20BurnableUpgradeable is Initializable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
    }

    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
    
    function burn(uint256 value) public virtual {
        _burn(_msgSender(), value);
    }

    
    function burnFrom(address account, uint256 value) public virtual {
        _spendAllowance(account, _msgSender(), value);
        _burn(account, value);
    }
}
