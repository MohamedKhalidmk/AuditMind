


pragma solidity ^0.8.20;

import {IERC7786Recipient} from "../interfaces/draft-IERC7786.sol";


abstract contract ERC7786Recipient is IERC7786Recipient {
    
    error ERC7786RecipientUnauthorizedGateway(address gateway, bytes sender);

    
    function receiveMessage(
        bytes32 receiveId,
        bytes calldata sender, 
        bytes calldata payload
    ) external payable returns (bytes4) {
        
        if (!_isAuthorizedGateway(msg.sender, sender)) {
            revert ERC7786RecipientUnauthorizedGateway(msg.sender, sender);
        }

        _processMessage(msg.sender, receiveId, sender, payload);

        return IERC7786Recipient.receiveMessage.selector;
    }

    
    function _isAuthorizedGateway(address gateway, bytes calldata sender) internal view virtual returns (bool);

    
    function _processMessage(
        address gateway,
        bytes32 receiveId,
        bytes calldata sender,
        bytes calldata payload
    ) internal virtual;
}
