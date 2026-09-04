


pragma solidity ^0.8.20;

import {IERC721} from "../../../interfaces/IERC721.sol";
import {ERC4337Utils, PackedUserOperation} from "../../utils/ERC4337Utils.sol";
import {Paymaster} from "../Paymaster.sol";


abstract contract PaymasterERC721Owner is Paymaster {
    IERC721 private immutable _token;

    constructor(IERC721 token_) {
        _token = token_;
    }

    
    function token() public virtual returns (IERC721) {
        return _token;
    }

    
    function _validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 ,
        uint256 
    ) internal virtual override returns (bytes memory context, uint256 validationData) {
        return (
            bytes(""),
            
            
            token().balanceOf(userOp.sender) == 0
                ? ERC4337Utils.SIG_VALIDATION_FAILED
                : ERC4337Utils.SIG_VALIDATION_SUCCESS
        );
    }
}
