


pragma solidity ^0.8.20;

import {ERC4337Utils, PackedUserOperation} from "../../utils/ERC4337Utils.sol";
import {IERC20, SafeERC20} from "../../../token/ERC20/utils/SafeERC20.sol";
import {Math} from "../../../utils/math/Math.sol";
import {PaymasterERC20} from "./PaymasterERC20.sol";


abstract contract PaymasterERC20Guarantor is PaymasterERC20 {
    using ERC4337Utils for *;
    using Math for *;
    using SafeERC20 for IERC20;

    
    event UserOperationGuaranteed(bytes32 indexed userOpHash, address indexed guarantor, uint256 prefundAmount);

    
    function _prefund(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        IERC20 token,
        uint256 tokenPrice,
        address prefunder_,
        uint256 prefundAmount_
    )
        internal
        virtual
        override
        returns (bool success, address prefunder, uint256 prefundAmount, bytes memory prefundContext)
    {
        address guarantor = _fetchGuarantor(userOp);
        bool isGuaranteed = guarantor != address(0);

        
        
        if (isGuaranteed) {
            
            
            if (userOp.paymasterPostOpGasLimit() < _postOpCost() + _guaranteedPostOpCost())
                return (false, prefunder_, prefundAmount_, "");

            
            
            uint256 guaranteedPostOpCost = _erc20Cost(_guaranteedPostOpCost() * userOp.maxFeePerGas(), tokenPrice);
            prefundAmount_ = prefundAmount_.saturatingAdd(guaranteedPostOpCost);
            prefunder_ = guarantor;
        }
        (success, prefunder, prefundAmount, prefundContext) = super._prefund(
            userOp,
            userOpHash,
            token,
            tokenPrice,
            prefunder_,
            prefundAmount_
        );
        if (prefunder == guarantor) {
            emit UserOperationGuaranteed(userOpHash, prefunder, prefundAmount);
        }
        return (success, prefunder, prefundAmount, abi.encodePacked(prefundContext, userOp.sender));
    }

    
    function _refund(
        IERC20 token,
        uint256 tokenPrice,
        uint256 actualAmount,
        uint256 actualUserOpFeePerGas,
        address prefunder,
        uint256 prefundAmount,
        bytes calldata prefundContext
    ) internal virtual override returns (bool refunded, uint256 effectiveAmount) {
        address userOpSender = address(bytes20(prefundContext[prefundContext.length - 20:]));

        
        
        
        
        
        
        
        if (prefunder != userOpSender) {
            
            
            
            uint256 guaranteedPostOpAmount = _erc20Cost(_guaranteedPostOpCost() * actualUserOpFeePerGas, tokenPrice);
            actualAmount += guaranteedPostOpAmount;
            effectiveAmount = actualAmount;

            
            if (token.trySafeTransferFrom(userOpSender, address(this), actualAmount)) {
                actualAmount = 0;
            }
        }

        uint256 returnedEffectiveAmount;
        bytes calldata forwardedContext = prefundContext[:prefundContext.length - 20];
        (refunded, returnedEffectiveAmount) = super._refund(
            token,
            tokenPrice,
            actualAmount,
            actualUserOpFeePerGas,
            prefunder,
            prefundAmount,
            forwardedContext
        );
        return (refunded, Math.ternary(prefunder != userOpSender, effectiveAmount, returnedEffectiveAmount));
    }

    
    function _postOpGasBudget(PackedUserOperation calldata userOp) internal view virtual override returns (uint256) {
        return
            super._postOpGasBudget(userOp) +
            Math.ternary(_fetchGuarantor(userOp) == address(0), 0, _guaranteedPostOpCost());
    }

    
    function _fetchGuarantor(PackedUserOperation calldata userOp) internal view virtual returns (address guarantor);

    
    function _guaranteedPostOpCost() internal view virtual returns (uint256) {
        return 15_000;
    }
}
