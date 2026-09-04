


pragma solidity ^0.8.26;

import {IERC721} from "../../interfaces/IERC721.sol";
import {IERC721Errors} from "../../interfaces/draft-IERC6093.sol";
import {BridgeNonFungible} from "./abstract/BridgeNonFungible.sol";



abstract contract BridgeERC721 is BridgeNonFungible {
    IERC721 private immutable _token;

    constructor(IERC721 token_) {
        _token = token_;
    }

    
    function token() public view virtual returns (IERC721) {
        return _token;
    }

    
    function crosschainTransferFrom(address from, bytes memory to, uint256 tokenId) public virtual returns (bytes32) {
        
        address spender = _msgSender();
        require(
            from == spender || token().isApprovedForAll(from, spender) || token().getApproved(tokenId) == spender,
            IERC721Errors.ERC721InsufficientApproval(spender, tokenId)
        );

        
        
        
        
        return _crosschainTransfer(from, to, tokenId);
    }

    
    function _onSend(address from, uint256 tokenId) internal virtual override {
        
        token().transferFrom(from, address(this), tokenId);
    }

    
    function _onReceive(address to, uint256 tokenId) internal virtual override {
        
        token().transferFrom(address(this), to, tokenId);
    }
}
