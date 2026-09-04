


pragma solidity ^0.8.26;

import {ERC721} from "../ERC721.sol";
import {BridgeNonFungible} from "../../../crosschain/bridges/abstract/BridgeNonFungible.sol";



abstract contract ERC721Crosschain is BridgeNonFungible, ERC721 {
    
    function crosschainTransferFrom(address from, bytes memory to, uint256 tokenId) public virtual returns (bytes32) {
        
        return _crosschainTransfer(from, to, tokenId);
    }

    
    function _onSend(address from, uint256 tokenId) internal virtual override {
        address previousOwner = _update(address(0), tokenId, _msgSender());
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        } else if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    
    function _onReceive(address to, uint256 tokenId) internal virtual override {
        _mint(to, tokenId);
    }
}
