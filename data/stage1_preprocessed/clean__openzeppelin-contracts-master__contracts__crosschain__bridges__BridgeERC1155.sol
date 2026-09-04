


pragma solidity ^0.8.26;

import {IERC1155} from "../../interfaces/IERC1155.sol";
import {IERC1155Receiver} from "../../interfaces/IERC1155Receiver.sol";
import {IERC1155Errors} from "../../interfaces/draft-IERC6093.sol";
import {ERC1155Holder} from "../../token/ERC1155/utils/ERC1155Holder.sol";
import {BridgeMultiToken} from "./abstract/BridgeMultiToken.sol";



abstract contract BridgeERC1155 is BridgeMultiToken, ERC1155Holder {
    IERC1155 private immutable _token;

    constructor(IERC1155 token_) {
        _token = token_;
    }

    
    function token() public view virtual returns (IERC1155) {
        return _token;
    }

    
    function crosschainTransferFrom(address from, bytes memory to, uint256 id, uint256 value) public returns (bytes32) {
        return crosschainTransferFrom(from, to, id, value, "");
    }

    
    function crosschainTransferFrom(
        address from,
        bytes memory to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public returns (bytes32) {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory values = new uint256[](1);
        ids[0] = id;
        values[0] = value;

        return crosschainTransferFrom(from, to, ids, values, data);
    }

    
    function crosschainTransferFrom(
        address from,
        bytes memory to,
        uint256[] memory ids,
        uint256[] memory values
    ) public returns (bytes32) {
        return crosschainTransferFrom(from, to, ids, values, "");
    }

    
    function crosschainTransferFrom(
        address from,
        bytes memory to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual returns (bytes32) {
        
        address spender = _msgSender();
        require(
            from == spender || token().isApprovedForAll(from, spender),
            IERC1155Errors.ERC1155MissingApprovalForAll(spender, from)
        );

        
        return _crosschainTransfer(from, to, ids, values, data);
    }

    
    function _onSend(address from, uint256[] memory ids, uint256[] memory values) internal virtual override {
        token().safeBatchTransferFrom(from, address(this), ids, values, "");
    }

    
    function _onReceive(
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal virtual override {
        token().safeBatchTransferFrom(address(this), to, ids, values, data);
    }

    
    function onERC1155Received(
        address operator,
        address ,
        uint256 ,
        uint256 ,
        bytes memory 
    ) public virtual override returns (bytes4) {
        return
            msg.sender == address(_token) && operator == address(this)
                ? IERC1155Receiver.onERC1155Received.selector
                : bytes4(0);
    }

    
    function onERC1155BatchReceived(
        address operator,
        address ,
        uint256[] memory ,
        uint256[] memory ,
        bytes memory 
    ) public virtual override returns (bytes4) {
        return
            msg.sender == address(_token) && operator == address(this)
                ? IERC1155Receiver.onERC1155BatchReceived.selector
                : bytes4(0);
    }
}
