


pragma solidity ^0.8.24;

import {IERC6372} from "../interfaces/IERC6372.sol";
import {Time} from "./types/Time.sol";


library ERC6372Utils {
    
    error ERC6372InconsistentClock();

    
    function blockNumberClockMode(IERC6372 instance) internal view returns (string memory) {
        return blockNumberClockMode(instance.clock());
    }

    
    function blockNumberClockMode(function() view returns (uint48) clock) internal view returns (string memory) {
        return blockNumberClockMode(clock());
    }

    
    function blockNumberClockMode(uint48 clock) internal view returns (string memory) {
        
        if (clock != Time.blockNumber()) {
            revert ERC6372InconsistentClock();
        }
        return "mode=blocknumber&from=default";
    }

    
    function timestampClockMode(IERC6372 instance) internal view returns (string memory) {
        return timestampClockMode(instance.clock());
    }

    
    function timestampClockMode(function() view returns (uint48) clock) internal view returns (string memory) {
        return timestampClockMode(clock());
    }

    
    function timestampClockMode(uint48 clock) internal view returns (string memory) {
        
        if (clock != Time.timestamp()) {
            revert ERC6372InconsistentClock();
        }
        return "mode=timestamp";
    }
}
