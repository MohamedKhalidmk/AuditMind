


pragma solidity ^0.8.26;

import {ERC1155} from "../ERC1155.sol";
import {BridgeMultiToken} from "../../../crosschain/bridges/abstract/BridgeMultiToken.sol";



abstract contract ERC1155Crosschain is BridgeMultiToken, ERC1155 {
    
    function crosschainTransferFrom(
        address from,
        bytes memory to,
        uint256 id,
        uint256 value
    ) public virtual returns (bytes32) {
        return crosschainTransferFrom(from, to, id, value, "");
    }

    
    function crosschainTransferFrom(
        address from,
        bytes memory to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public virtual returns (bytes32) {
        _checkAuthorized(_msgSender(), from);

        uint256[] memory ids = new uint256[](1);
        uint256[] memory values = new uint256[](1);
        ids[0] = id;
        values[0] = value;
        return _crosschainTransfer(from, to, ids, values, data);
    }

    
    function crosschainTransferFrom(
        address from,
        bytes memory to,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual returns (bytes32) {
        return crosschainTransferFrom(from, to, ids, values, "");
    }

    
    function crosschainTransferFrom(
        address from,
        bytes memory to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual returns (bytes32) {
        _checkAuthorized(_msgSender(), from);
        return _crosschainTransfer(from, to, ids, values, data);
    }

    
    function _onSend(address from, uint256[] memory ids, uint256[] memory values) internal virtual override {
        _burnBatch(from, ids, values);
    }

    
    function _onReceive(
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal virtual override {
        _mintBatch(to, ids, values, data);
    }
}
