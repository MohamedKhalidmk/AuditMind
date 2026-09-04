


pragma solidity ^0.8.27;

import {IERC7786GatewaySource} from "../interfaces/draft-IERC7786.sol";
import {ERC7786Recipient} from "./ERC7786Recipient.sol";
import {ERC7579Utils, Mode, CallType, ExecType} from "../account/utils/draft-ERC7579Utils.sol";
import {Bytes} from "../utils/Bytes.sol";


contract CrosschainRemoteExecutor is ERC7786Recipient {
    using Bytes for bytes;
    using ERC7579Utils for *;

    
    address private _gateway;

    
    bytes private _controller;

    
    event CrosschainControllerSet(address gateway, bytes controller);

    
    error AccessRestricted();

    constructor(address initialGateway, bytes memory initialController) {
        _setup(initialGateway, initialController);
    }

    
    function gateway() public view virtual returns (address) {
        return _gateway;
    }

    
    function controller() public view virtual returns (bytes memory) {
        return _controller;
    }

    
    function reconfigure(address newGateway, bytes memory newController) public virtual {
        require(msg.sender == address(this), AccessRestricted());
        _setup(newGateway, newController);
    }

    
    function _setup(address gateway_, bytes memory controller_) internal virtual {
        
        
        IERC7786GatewaySource(gateway_).supportsAttribute(bytes4(0));

        _gateway = gateway_;
        _controller = controller_;

        emit CrosschainControllerSet(gateway_, controller_);
    }

    
    function _isAuthorizedGateway(
        address instance,
        bytes calldata sender
    ) internal view virtual override returns (bool) {
        return gateway() == instance && controller().equal(sender);
    }

    
    function _processMessage(
        address ,
        bytes32 ,
        bytes calldata ,
        bytes calldata payload
    ) internal virtual override {
        
        (CallType callType, ExecType execType, , ) = Mode.wrap(bytes32(payload[0x00:0x20])).decodeMode();
        bytes calldata executionCalldata = payload[0x20:];

        if (callType == ERC7579Utils.CALLTYPE_SINGLE) {
            executionCalldata.execSingle(execType);
        } else if (callType == ERC7579Utils.CALLTYPE_BATCH) {
            executionCalldata.execBatch(execType);
        } else if (callType == ERC7579Utils.CALLTYPE_DELEGATECALL) {
            executionCalldata.execDelegateCall(execType);
        } else revert ERC7579Utils.ERC7579UnsupportedCallType(callType);
    }
}
