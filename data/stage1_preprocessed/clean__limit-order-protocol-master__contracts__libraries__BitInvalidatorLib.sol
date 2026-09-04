

pragma solidity ^0.8.0;


library BitInvalidatorLib {
    
    error BitInvalidatedOrder();

    struct Data {
        mapping(uint256 slotIndex => uint256 slotData) _raw;
    }

    
    function checkSlot(Data storage self, uint256 nonce) internal view returns(uint256) {
        uint256 invalidatorSlot = nonce >> 8;
        return self._raw[invalidatorSlot];
    }

    
    function checkAndInvalidate(Data storage self, uint256 nonce) internal {
        uint256 invalidatorSlot = nonce >> 8;
        uint256 invalidatorBit = 1 << (nonce & 0xff);
        uint256 invalidator = self._raw[invalidatorSlot];
        if (invalidator & invalidatorBit == invalidatorBit) revert BitInvalidatedOrder();
        self._raw[invalidatorSlot] = invalidator | invalidatorBit;
    }

    
    function massInvalidate(Data storage self, uint256 nonce, uint256 additionalMask) internal returns(uint256 result) {
        uint256 invalidatorSlot = nonce >> 8;
        uint256 invalidatorBits = (1 << (nonce & 0xff)) | additionalMask;
        result = self._raw[invalidatorSlot] | invalidatorBits;
        self._raw[invalidatorSlot] = result;
    }
}
