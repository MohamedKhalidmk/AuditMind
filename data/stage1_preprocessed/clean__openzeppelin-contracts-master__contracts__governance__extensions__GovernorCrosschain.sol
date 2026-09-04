


pragma solidity ^0.8.26;

import {Governor} from "../Governor.sol";
import {Mode} from "../../account/utils/draft-ERC7579Utils.sol";
import {IERC7786GatewaySource} from "../../interfaces/draft-IERC7786.sol";


abstract contract GovernorCrosschain is Governor {
    
    function relayCrosschain(
        address gateway,
        bytes memory executor,
        Mode mode,
        bytes memory executionCalldata
    ) public virtual onlyGovernance {
        _crosschainExecute(gateway, executor, mode, executionCalldata);
    }

    
    function _crosschainExecute(
        address gateway,
        bytes memory executor,
        Mode mode,
        bytes memory executionCalldata
    ) internal virtual {
        IERC7786GatewaySource(gateway).sendMessage(executor, abi.encodePacked(mode, executionCalldata), new bytes[](0));
    }
}
