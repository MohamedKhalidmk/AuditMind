


pragma solidity ^0.8.26;

import {InteroperableAddress} from "../../../utils/draft-InteroperableAddress.sol";
import {Context} from "../../../utils/Context.sol";
import {ERC7786Recipient} from "../../ERC7786Recipient.sol";
import {CrosschainLinked} from "../../CrosschainLinked.sol";


abstract contract BridgeFungible is Context, CrosschainLinked {
    
    event CrosschainFungibleTransferSent(bytes32 indexed sendId, address indexed from, bytes to, uint256 amount);

    
    event CrosschainFungibleTransferReceived(bytes32 indexed receiveId, bytes from, address indexed to, uint256 amount);

    
    error CrosschainFungibleEmptyAddress();

    
    function crosschainTransfer(bytes memory to, uint256 amount) public virtual returns (bytes32) {
        return _crosschainTransfer(_msgSender(), to, amount);
    }

    
    function _crosschainTransfer(address from, bytes memory to, uint256 amount) internal virtual returns (bytes32) {
        _onSend(from, amount);

        (bytes2 chainType, bytes memory chainReference, bytes memory addr) = InteroperableAddress.parseV1(to);
        require(addr.length > 0, CrosschainFungibleEmptyAddress());

        bytes32 sendId = _sendMessageToCounterpart(
            InteroperableAddress.formatV1(chainType, chainReference, hex""),
            abi.encode(InteroperableAddress.formatEvmV1(block.chainid, from), addr, amount),
            new bytes[](0)
        );

        emit CrosschainFungibleTransferSent(sendId, from, to, amount);

        return sendId;
    }

    
    function _processMessage(
        address ,
        bytes32 receiveId,
        bytes calldata ,
        bytes calldata payload
    ) internal virtual override {
        

        
        (bytes memory from, bytes memory toEvm, uint256 amount) = abi.decode(payload, (bytes, bytes, uint256));
        address to = address(bytes20(toEvm));

        _onReceive(to, amount);

        emit CrosschainFungibleTransferReceived(receiveId, from, to, amount);
    }

    
    function _onSend(address from, uint256 amount) internal virtual;

    
    function _onReceive(address to, uint256 amount) internal virtual;
}
