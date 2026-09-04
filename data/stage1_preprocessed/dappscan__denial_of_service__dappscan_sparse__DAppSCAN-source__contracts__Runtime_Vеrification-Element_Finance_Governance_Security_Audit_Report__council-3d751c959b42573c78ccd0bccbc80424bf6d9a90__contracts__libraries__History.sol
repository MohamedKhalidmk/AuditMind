
pragma solidity ^0.8.3;

import "./Storage.sol";








library History {
    
    
    
    
    
    
    
    

    
    
    
    
    struct HistoricalBalances {
        string name;
        
        bytes32 cachedPointer;
    }

    
    
    
    
    function load(string memory name)
        internal
        pure
        returns (HistoricalBalances memory)
    {
        mapping(address => uint256[]) storage storageData =
            Storage.mappingAddressToUnit256ArrayPtr(name);
        bytes32 pointer;
        assembly {
            pointer := storageData.slot
        }
        return HistoricalBalances(name, pointer);
    }

    
    
    
    
    
    function _getMapping(bytes32 pointer)
        private
        pure
        returns (mapping(address => uint256[]) storage storageData)
    {
        assembly {
            storageData.slot := pointer
        }
    }

    
    
    
    
    
    
    function push(
        HistoricalBalances memory wrapper,
        address who,
        uint256 data
    ) internal {
        
        
        require(data < uint256(1) << 192, "OoB");
        
        mapping(address => uint256[]) storage storageMapping =
            _getMapping(wrapper.cachedPointer);
        
        uint256[] storage storageData = storageMapping[who];
        
        uint256 blockNumber = block.number << 192;
        
        
        uint256 packedData = blockNumber | data;
        
        (uint256 minIndex, uint256 length) = _loadBounds(storageData);
        
        uint256 loadedBlockNumber = 0;
        if (length != 0) {
            (loadedBlockNumber, ) = _loadAndUnpack(storageData, length - 1);
        }
        
        uint256 index = length;
        
        
        if (loadedBlockNumber == block.number) {
            index = length - 1;
        }
        
        assembly {
            
            sstore(
                add(
                    
                    add(storageData.slot, 1),
                    
                    index
                ),
                packedData
            )
        }
        
        if (loadedBlockNumber != block.number) {
            _setBounds(storageData, minIndex, length + 1);
        }
    }

    
    
    
    
    function loadTop(HistoricalBalances memory wrapper, address who)
        internal
        view
        returns (uint256)
    {
        
        uint256[] storage userData = _getMapping(wrapper.cachedPointer)[who];
        
        (, uint256 length) = _loadBounds(userData);
        
        if (length == 0) {
            return 0;
        }
        
        (, uint256 storedData) = _loadAndUnpack(userData, length - 1);
        
        return (storedData);
    }

    
    
    
    
    
    
    function find(
        HistoricalBalances memory wrapper,
        address who,
        uint256 blocknumber
    ) internal view returns (uint256) {
        
        mapping(address => uint256[]) storage storageMapping =
            _getMapping(wrapper.cachedPointer);
        
        uint256[] storage storageData = storageMapping[who];
        
        (uint256 minIndex, uint256 length) = _loadBounds(storageData);
        
        (, uint256 loadedData) =
            _find(storageData, blocknumber, 0, minIndex, length);
        
        return (loadedData);
    }

    
    
    
    
    
    
    
    function findAndClear(
        HistoricalBalances memory wrapper,
        address who,
        uint256 blocknumber,
        uint256 staleBlock
    ) internal returns (uint256) {
        
        mapping(address => uint256[]) storage storageMapping =
            _getMapping(wrapper.cachedPointer);
        
        uint256[] storage storageData = storageMapping[who];
        
        (uint256 minIndex, uint256 length) = _loadBounds(storageData);
        
        (uint256 staleIndex, uint256 loadedData) =
            _find(storageData, blocknumber, staleBlock, minIndex, length);
        
        
        
        
        if (staleIndex > minIndex) {
            
            _clear(minIndex, staleIndex, storageData);
            
            _setBounds(storageData, staleIndex, length);
        }
        return (loadedData);
    }

    
    
    
    
    
    
    
    
    
    function _find(
        uint256[] storage data,
        uint256 blocknumber,
        uint256 staleBlock,
        uint256 startingMinIndex,
        uint256 length
    ) private view returns (uint256, uint256) {
        
        
        uint256 maxIndex = length - 1;
        uint256 minIndex = startingMinIndex;
        uint256 staleIndex = 0;

        
        

        
        
        
        
        while (minIndex != maxIndex) {
            
            
            uint256 mid = maxIndex + minIndex - (minIndex + maxIndex) / 2;
            
            (uint256 pastBlock, uint256 loadedData) = _loadAndUnpack(data, mid);

            
            if (pastBlock == blocknumber) {
                
                return (staleIndex, loadedData);

                
            } else if (pastBlock < blocknumber) {
                
                if (pastBlock < staleBlock) {
                    
                    staleIndex = mid;
                }
                
                minIndex = mid;

                
            } else {
                
                maxIndex = mid - 1;
            }
        }

        
        (uint256 _pastBlock, uint256 _loadedData) =
            _loadAndUnpack(data, minIndex);
        
        
        require(_pastBlock <= blocknumber, "Search Failure");
        return (staleIndex, _loadedData);
    }

    
    
    
    
    
    function _clear(
        uint256 oldMin,
        uint256 newMin,
        uint256[] storage data
    ) private {
        
        
        assembly {
            
            
            let dataLocation := add(data.slot, 1)
            
            
            for {
                let i := oldMin
            } lt(i, newMin) {
                i := add(i, 1)
            } {
                
                sstore(add(dataLocation, i), 0)
            }
        }
    }

    
    
    
    
    function _loadAndUnpack(uint256[] storage data, uint256 i)
        private
        view
        returns (uint256, uint256)
    {
        
        
        uint256 loaded;
        assembly {
            loaded := sload(add(add(data.slot, 1), i))
        }
        
        return (
            loaded >> 192,
            loaded &
                0x0000000000000000ffffffffffffffffffffffffffffffffffffffffffffffff
        );
    }

    
    
    
    
    
    function _setBounds(
        uint256[] storage data,
        uint256 minIndex,
        uint256 length
    ) private {
        assembly {
            
            let clearedLength := and(
                length,
                0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff
            )
            
            let minInd := shl(128, minIndex)
            
            let packed := or(minInd, clearedLength)
            
            sstore(data.slot, packed)
        }
    }

    
    
    
    
    function _loadBounds(uint256[] storage data)
        private
        view
        returns (uint256 minInd, uint256 length)
    {
        
        uint256 packedData;
        assembly {
            packedData := sload(data.slot)
        }
        
        minInd = packedData >> 128;
        
        length =
            packedData &
            0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
    }
}
