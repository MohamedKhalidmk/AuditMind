


pragma solidity ^0.8.20;

import {IERC20, ERC20} from "../ERC20.sol";
import {SafeERC20} from "../utils/SafeERC20.sol";
import {Math} from "../../../utils/math/Math.sol";


abstract contract ERC20Wrapper is ERC20 {
    IERC20 private immutable _underlying;

    
    error ERC20InvalidUnderlying(address token);

    constructor(IERC20 underlyingToken) {
        if (address(underlyingToken) == address(this)) {
            revert ERC20InvalidUnderlying(address(this));
        }
        _underlying = underlyingToken;
    }

    
    function decimals() public view virtual override returns (uint8) {
        (bool success, uint8 decimals_) = SafeERC20.tryGetDecimals(_underlying);
        return uint8(Math.ternary(success, decimals_, super.decimals())); 
    }

    
    function underlying() public view returns (IERC20) {
        return _underlying;
    }

    
    function depositFor(address account, uint256 value) public virtual returns (bool) {
        address sender = _msgSender();
        if (sender == address(this)) {
            revert ERC20InvalidSender(address(this));
        }
        if (account == address(this)) {
            revert ERC20InvalidReceiver(account);
        }
        SafeERC20.safeTransferFrom(_underlying, sender, address(this), value);
        _mint(account, value);
        return true;
    }

    
    function withdrawTo(address account, uint256 value) public virtual returns (bool) {
        if (account == address(this)) {
            revert ERC20InvalidReceiver(account);
        }
        _burn(_msgSender(), value);
        SafeERC20.safeTransfer(_underlying, account, value);
        return true;
    }

    
    function _recover(address account) internal virtual returns (uint256) {
        uint256 value = _underlying.balanceOf(address(this)) - totalSupply();
        _mint(account, value);
        return value;
    }
}
