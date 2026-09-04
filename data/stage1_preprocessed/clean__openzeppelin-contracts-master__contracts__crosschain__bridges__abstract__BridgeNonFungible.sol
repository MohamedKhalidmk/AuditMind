


pragma solidity ^0.8.26;

import {InteroperableAddress} from "../../../utils/draft-InteroperableAddress.sol";
import {Context} from "../../../utils/Context.sol";
import {ERC7786Recipient} from "../../ERC7786Recipient.sol";
import {CrosschainLinked} from "../../CrosschainLinked.sol";


abstract contract BridgeNonFungible is Context, CrosschainLinked {
    
    event CrosschainNonFungibleTransferSent(bytes32 indexed sendId, address indexed from, bytes to, uint256 tokenId);

    
    event CrosschainNonFungibleTransferReceived(
        bytes32 indexed receiveId,
        bytes from,
        address indexed to,
        uint256 tokenId
    );

    
    error CrosschainNonFungibleEmptyAddress();

    
    function _crosschainTransfer(address from, bytes memory to, uint256 tokenId) internal virtual returns (bytes32) {
        _onSend(from, tokenId);

        (bytes2 chainType, bytes memory chainReference, bytes memory addr) = InteroperableAddress.parseV1(to);
        require(addr.length > 0, CrosschainNonFungibleEmptyAddress());

        bytes32 sendId = _sendMessageToCounterpart(
            InteroperableAddress.formatV1(chainType, chainReference, hex""),
            abi.encode(InteroperableAddress.formatEvmV1(block.chainid, from), addr, tokenId),
            new bytes[](0)
        );

        emit CrosschainNonFungibleTransferSent(sendId, from, to, tokenId);

        return sendId;
    }

    
    function _processMessage(
        address ,
        bytes32 receiveId,
        bytes calldata ,
        bytes calldata payload
    ) internal virtual override {
        
        (bytes memory from, bytes memory toEvm, uint256 tokenId) = abi.decode(payload, (bytes, bytes, uint256));
        address to = address(bytes20(toEvm));

        _onReceive(to, tokenId);

        emit CrosschainNonFungibleTransferReceived(receiveId, from, to, tokenId);
    }

    
    function _onSend(address from, uint256 tokenId) internal virtual;

    
    function _onReceive(address to, uint256 tokenId) internal virtual;
}
