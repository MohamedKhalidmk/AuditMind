


pragma solidity ^0.8.26;

import {InteroperableAddress} from "../../../utils/draft-InteroperableAddress.sol";
import {Context} from "../../../utils/Context.sol";
import {ERC7786Recipient} from "../../ERC7786Recipient.sol";
import {CrosschainLinked} from "../../CrosschainLinked.sol";


abstract contract BridgeMultiToken is Context, CrosschainLinked {
    using InteroperableAddress for bytes;

    event CrosschainMultiTokenTransferSent(
        bytes32 indexed sendId,
        address indexed from,
        bytes to,
        uint256[] ids,
        uint256[] values,
        bytes data
    );
    event CrosschainMultiTokenTransferReceived(
        bytes32 indexed receiveId,
        bytes from,
        address indexed to,
        uint256[] ids,
        uint256[] values,
        bytes data
    );

    
    error CrosschainMultiTokenEmptyAddress();

    
    function _crosschainTransfer(
        address from,
        bytes memory to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal virtual returns (bytes32) {
        _onSend(from, ids, values);

        (bytes2 chainType, bytes memory chainReference, bytes memory addr) = to.parseV1();
        require(addr.length > 0, CrosschainMultiTokenEmptyAddress());

        bytes32 sendId = _sendMessageToCounterpart(
            InteroperableAddress.formatV1(chainType, chainReference, hex""),
            abi.encode(InteroperableAddress.formatEvmV1(block.chainid, from), addr, ids, values, data),
            new bytes[](0)
        );

        emit CrosschainMultiTokenTransferSent(sendId, from, to, ids, values, data);
        return sendId;
    }

    
    function _processMessage(
        address ,
        bytes32 receiveId,
        bytes calldata ,
        bytes calldata payload
    ) internal virtual override {
        

        
        (bytes memory from, bytes memory toEvm, uint256[] memory ids, uint256[] memory values, bytes memory data) = abi
            .decode(payload, (bytes, bytes, uint256[], uint256[], bytes));
        address to = address(bytes20(toEvm));

        _onReceive(to, ids, values, data);

        emit CrosschainMultiTokenTransferReceived(receiveId, from, to, ids, values, data);
    }

    
    function _onSend(address from, uint256[] memory ids, uint256[] memory values) internal virtual;

    
    function _onReceive(address to, uint256[] memory ids, uint256[] memory values, bytes memory data) internal virtual;
}
