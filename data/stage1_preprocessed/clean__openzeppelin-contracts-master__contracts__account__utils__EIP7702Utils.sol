


pragma solidity ^0.8.20;


library EIP7702Utils {
    bytes3 internal constant EIP7702_PREFIX = 0xef0100;

    
    function fetchDelegate(address account) internal view returns (address) {
        bytes32 delegation;
        assembly ("memory-safe") {
            extcodecopy(account, 0x00, 0x00, 0x20)
            delegation := mload(0x00)
        }
        return bytes3(delegation) == EIP7702_PREFIX ? address(bytes20(delegation << 24)) : address(0);
    }
}
