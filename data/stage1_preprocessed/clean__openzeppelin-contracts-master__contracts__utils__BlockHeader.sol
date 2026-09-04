


pragma solidity ^0.8.26;

import {SafeCast} from "./math/SafeCast.sol";
import {Blockhash} from "./Blockhash.sol";
import {Memory} from "./Memory.sol";
import {RLP} from "./RLP.sol";


library BlockHeader {
    using RLP for *;
    using SafeCast for *;

    
    enum HeaderField {
        ParentHash, 
        OmmersHash, 
        Coinbase, 
        StateRoot, 
        TransactionsRoot, 
        ReceiptsRoot, 
        LogsBloom, 
        Difficulty, 
        Number, 
        GasLimit, 
        GasUsed, 
        Timestamp, 
        ExtraData, 
        PrevRandao, 
        Nonce, 
        BaseFeePerGas, 
        WithdrawalsRoot, 
        BlobGasUsed, 
        ExcessBlobGas, 
        ParentBeaconBlockRoot, 
        RequestsHash, 
        BlockAccessListHash 
    }

    
    
    error FieldNotPresentInBlockHeader(HeaderField);

    
    function verifyBlockHeader(bytes memory headerRLP) internal view returns (bool result) {
        return Blockhash.blockHash(getNumber(headerRLP)) == keccak256(headerRLP);
    }

    
    function verifyBlockHeader(Memory.Slice[] memory fields, bytes32 headerHash) internal view returns (bool) {
        return Blockhash.blockHash(getNumber(fields)) == headerHash;
    }

    
    function parseHeader(bytes memory headerRLP) internal pure returns (Memory.Slice[] memory) {
        return RLP.decodeList(headerRLP);
    }

    
    function getParentHash(bytes memory headerRLP) internal pure returns (bytes32) {
        return _getField(headerRLP, HeaderField.ParentHash).readBytes32();
    }

    
    function getParentHash(Memory.Slice[] memory fields) internal pure returns (bytes32) {
        return _getField(fields, HeaderField.ParentHash).readBytes32();
    }

    
    function getOmmersHash(bytes memory headerRLP) internal pure returns (bytes32) {
        return _getField(headerRLP, HeaderField.OmmersHash).readBytes32();
    }

    
    function getOmmersHash(Memory.Slice[] memory fields) internal pure returns (bytes32) {
        return _getField(fields, HeaderField.OmmersHash).readBytes32();
    }

    
    function getCoinbase(bytes memory headerRLP) internal pure returns (address) {
        return _getField(headerRLP, HeaderField.Coinbase).readAddress();
    }

    
    function getCoinbase(Memory.Slice[] memory fields) internal pure returns (address) {
        return _getField(fields, HeaderField.Coinbase).readAddress();
    }

    
    function getStateRoot(bytes memory headerRLP) internal pure returns (bytes32) {
        return _getField(headerRLP, HeaderField.StateRoot).readBytes32();
    }

    
    function getStateRoot(Memory.Slice[] memory fields) internal pure returns (bytes32) {
        return _getField(fields, HeaderField.StateRoot).readBytes32();
    }

    
    function getTransactionsRoot(bytes memory headerRLP) internal pure returns (bytes32) {
        return _getField(headerRLP, HeaderField.TransactionsRoot).readBytes32();
    }

    
    function getTransactionsRoot(Memory.Slice[] memory fields) internal pure returns (bytes32) {
        return _getField(fields, HeaderField.TransactionsRoot).readBytes32();
    }

    
    function getReceiptsRoot(bytes memory headerRLP) internal pure returns (bytes32) {
        return _getField(headerRLP, HeaderField.ReceiptsRoot).readBytes32();
    }

    
    function getReceiptsRoot(Memory.Slice[] memory fields) internal pure returns (bytes32) {
        return _getField(fields, HeaderField.ReceiptsRoot).readBytes32();
    }

    
    function getLogsBloom(bytes memory headerRLP) internal pure returns (bytes memory) {
        return _getField(headerRLP, HeaderField.LogsBloom).readBytes();
    }

    
    function getLogsBloom(Memory.Slice[] memory fields) internal pure returns (bytes memory) {
        return _getField(fields, HeaderField.LogsBloom).readBytes();
    }

    
    function getDifficulty(bytes memory headerRLP) internal pure returns (uint256) {
        return _getField(headerRLP, HeaderField.Difficulty).readUint256();
    }

    
    function getDifficulty(Memory.Slice[] memory fields) internal pure returns (uint256) {
        return _getField(fields, HeaderField.Difficulty).readUint256();
    }

    
    function getNumber(bytes memory headerRLP) internal pure returns (uint256) {
        return _getField(headerRLP, HeaderField.Number).readUint256();
    }

    
    function getNumber(Memory.Slice[] memory fields) internal pure returns (uint256) {
        return _getField(fields, HeaderField.Number).readUint256();
    }

    
    function getGasUsed(bytes memory headerRLP) internal pure returns (uint256) {
        return _getField(headerRLP, HeaderField.GasUsed).readUint256();
    }

    
    function getGasUsed(Memory.Slice[] memory fields) internal pure returns (uint256) {
        return _getField(fields, HeaderField.GasUsed).readUint256();
    }

    
    function getGasLimit(bytes memory headerRLP) internal pure returns (uint256) {
        return _getField(headerRLP, HeaderField.GasLimit).readUint256();
    }

    
    function getGasLimit(Memory.Slice[] memory fields) internal pure returns (uint256) {
        return _getField(fields, HeaderField.GasLimit).readUint256();
    }

    
    function getTimestamp(bytes memory headerRLP) internal pure returns (uint256) {
        return _getField(headerRLP, HeaderField.Timestamp).readUint256();
    }

    
    function getTimestamp(Memory.Slice[] memory fields) internal pure returns (uint256) {
        return _getField(fields, HeaderField.Timestamp).readUint256();
    }

    
    function getExtraData(bytes memory headerRLP) internal pure returns (bytes memory) {
        return _getField(headerRLP, HeaderField.ExtraData).readBytes();
    }

    
    function getExtraData(Memory.Slice[] memory fields) internal pure returns (bytes memory) {
        return _getField(fields, HeaderField.ExtraData).readBytes();
    }

    
    function getPrevRandao(bytes memory headerRLP) internal pure returns (bytes32) {
        return _getField(headerRLP, HeaderField.PrevRandao).readBytes32();
    }

    
    function getPrevRandao(Memory.Slice[] memory fields) internal pure returns (bytes32) {
        return _getField(fields, HeaderField.PrevRandao).readBytes32();
    }

    
    function getNonce(bytes memory headerRLP) internal pure returns (bytes8) {
        return bytes8(_getField(headerRLP, HeaderField.Nonce).readUint256().toUint64());
    }

    
    function getNonce(Memory.Slice[] memory fields) internal pure returns (bytes8) {
        return bytes8(_getField(fields, HeaderField.Nonce).readUint256().toUint64());
    }

    
    function getBaseFeePerGas(bytes memory headerRLP) internal pure returns (uint256) {
        return _getField(headerRLP, HeaderField.BaseFeePerGas).readUint256();
    }

    
    function getBaseFeePerGas(Memory.Slice[] memory fields) internal pure returns (uint256) {
        return _getField(fields, HeaderField.BaseFeePerGas).readUint256();
    }

    
    function getWithdrawalsRoot(bytes memory headerRLP) internal pure returns (bytes32) {
        return _getField(headerRLP, HeaderField.WithdrawalsRoot).readBytes32();
    }

    
    function getWithdrawalsRoot(Memory.Slice[] memory fields) internal pure returns (bytes32) {
        return _getField(fields, HeaderField.WithdrawalsRoot).readBytes32();
    }

    
    function getBlobGasUsed(bytes memory headerRLP) internal pure returns (uint64) {
        return _getField(headerRLP, HeaderField.BlobGasUsed).readUint256().toUint64();
    }

    
    function getBlobGasUsed(Memory.Slice[] memory fields) internal pure returns (uint64) {
        return _getField(fields, HeaderField.BlobGasUsed).readUint256().toUint64();
    }

    
    function getExcessBlobGas(bytes memory headerRLP) internal pure returns (uint64) {
        return _getField(headerRLP, HeaderField.ExcessBlobGas).readUint256().toUint64();
    }

    
    function getExcessBlobGas(Memory.Slice[] memory fields) internal pure returns (uint64) {
        return _getField(fields, HeaderField.ExcessBlobGas).readUint256().toUint64();
    }

    
    function getParentBeaconBlockRoot(bytes memory headerRLP) internal pure returns (bytes32) {
        return _getField(headerRLP, HeaderField.ParentBeaconBlockRoot).readBytes32();
    }

    
    function getParentBeaconBlockRoot(Memory.Slice[] memory fields) internal pure returns (bytes32) {
        return _getField(fields, HeaderField.ParentBeaconBlockRoot).readBytes32();
    }

    
    function getRequestsHash(bytes memory headerRLP) internal pure returns (bytes32) {
        return _getField(headerRLP, HeaderField.RequestsHash).readBytes32();
    }

    
    function getRequestsHash(Memory.Slice[] memory fields) internal pure returns (bytes32) {
        return _getField(fields, HeaderField.RequestsHash).readBytes32();
    }

    
    function getBlockAccessListHash(bytes memory headerRLP) internal pure returns (bytes32) {
        return _getField(headerRLP, HeaderField.BlockAccessListHash).readBytes32();
    }

    
    function getBlockAccessListHash(Memory.Slice[] memory fields) internal pure returns (bytes32) {
        return _getField(fields, HeaderField.BlockAccessListHash).readBytes32();
    }

    
    function _getField(bytes memory headerRLP, HeaderField field) private pure returns (Memory.Slice result) {
        Memory.Pointer fmp = Memory.getFreeMemoryPointer();
        result = _getField(parseHeader(headerRLP), field);
        Memory.unsafeSetFreeMemoryPointer(fmp);
    }

    
    function _getField(Memory.Slice[] memory fields, HeaderField field) private pure returns (Memory.Slice) {
        require(uint8(field) < fields.length, FieldNotPresentInBlockHeader(field));
        return fields[uint8(field)];
    }
}
