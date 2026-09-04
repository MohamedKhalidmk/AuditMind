


pragma solidity ^0.8.26;

import {ERC20} from "../ERC20.sol";
import {BridgeFungible} from "../../../crosschain/bridges/abstract/BridgeFungible.sol";



abstract contract ERC20Crosschain is ERC20, BridgeFungible {
    
    function crosschainTransferFrom(address from, bytes memory to, uint256 amount) public virtual returns (bytes32) {
        _spendAllowance(from, _msgSender(), amount);
        return _crosschainTransfer(from, to, amount);
    }

    
    function _onSend(address from, uint256 amount) internal virtual override {
        _burn(from, amount);
    }

    
    function _onReceive(address to, uint256 amount) internal virtual override {
        _mint(to, amount);
    }
}
