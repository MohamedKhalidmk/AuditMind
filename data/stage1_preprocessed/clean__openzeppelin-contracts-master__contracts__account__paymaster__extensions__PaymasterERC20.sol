


pragma solidity ^0.8.20;

import {ERC4337Utils, PackedUserOperation} from "../../utils/ERC4337Utils.sol";
import {IERC20, SafeERC20} from "../../../token/ERC20/utils/SafeERC20.sol";
import {Math} from "../../../utils/math/Math.sol";
import {SafeCast} from "../../../utils/math/SafeCast.sol";
import {Paymaster} from "../Paymaster.sol";


abstract contract PaymasterERC20 is Paymaster {
    using ERC4337Utils for *;
    using Math for *;
    using SafeCast for *;
    using SafeERC20 for IERC20;

    
    event UserOperationSponsored(
        bytes32 indexed userOpHash,
        address indexed token,
        uint256 tokenAmount,
        uint256 tokenPerNative
    );

    
    error PaymasterERC20FailedRefund(IERC20 token, uint256 prefundAmount, uint256 actualAmount, bytes prefundContext);

    
    function _validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) internal virtual override returns (bytes memory context, uint256 validationData) {
        IERC20 token;
        uint256 tokenPerNative;
        address userOpSender = userOp.sender;
        (validationData, token, tokenPerNative) = _fetchDetails(userOp, userOpHash);

        if (uint160(validationData) == ERC4337Utils.SIG_VALIDATION_FAILED || tokenPerNative < _minTokensPerNative())
            return (bytes(""), ERC4337Utils.SIG_VALIDATION_FAILED);

        
        
        
        
        
        
        
        
        
        uint256 penaltyGas = _postOpGasPenalty(
            userOp.paymasterPostOpGasLimit().saturatingSub(_postOpGasBudget(userOp))
        );

        
        
        
        
        
        
        uint256 maxTokenCost = _erc20Cost(
            _postOpCost().saturatingAdd(penaltyGas).saturatingMul(userOp.maxFeePerGas()).saturatingAdd(maxCost),
            tokenPerNative
        );
        (bool success, address prefunder, uint256 prefundAmount, bytes memory prefundContext) = _prefund(
            userOp,
            userOpHash,
            token,
            tokenPerNative,
            userOpSender,
            maxTokenCost
        );

        return
            success
                ? (
                    abi.encodePacked(
                        userOpHash,
                        token,
                        tokenPerNative,
                        prefundAmount,
                        prefunder,
                        penaltyGas,
                        prefundContext
                    ),
                    validationData
                )
                : (bytes(""), ERC4337Utils.SIG_VALIDATION_FAILED);
    }

    
    function _prefund(
        PackedUserOperation calldata ,
        bytes32 ,
        IERC20 token,
        uint256 ,
        address prefunder_,
        uint256 prefundAmount_
    ) internal virtual returns (bool success, address prefunder, uint256 prefundAmount, bytes memory prefundContext) {
        return (token.trySafeTransferFrom(prefunder_, address(this), prefundAmount_), prefunder_, prefundAmount_, "");
    }

    
    function _postOp(
        PostOpMode ,
        bytes calldata context,
        uint256 actualGasCost,
        uint256 actualUserOpFeePerGas
    ) internal virtual override {
        bytes32 userOpHash = bytes32(context[0x00:0x20]);
        IERC20 token = IERC20(address(bytes20(context[0x20:0x34])));
        uint256 tokenPerNative = uint256(bytes32(context[0x34:0x54]));
        uint256 prefundAmount = uint256(bytes32(context[0x54:0x74]));
        address prefunder = address(bytes20(context[0x74:0x88]));
        uint256 penaltyGas = uint256(bytes32(context[0x88:0xA8]));
        bytes calldata prefundContext = context[0xA8:];

        
        
        
        
        
        
        uint256 actualTokenCost = _erc20Cost(
            _postOpCost().saturatingAdd(penaltyGas).saturatingMul(actualUserOpFeePerGas).saturatingAdd(actualGasCost),
            tokenPerNative
        );
        (bool success, uint256 actualAmount) = _refund(
            token,
            tokenPerNative,
            actualTokenCost,
            actualUserOpFeePerGas,
            prefunder,
            prefundAmount,
            prefundContext
        );
        if (!success) revert PaymasterERC20FailedRefund(token, prefundAmount, actualAmount, prefundContext);

        emit UserOperationSponsored(userOpHash, address(token), actualAmount, tokenPerNative);
    }

    
    function _refund(
        IERC20 token,
        uint256 ,
        uint256 actualAmount_,
        uint256 ,
        address prefunder,
        uint256 prefundAmount,
        bytes calldata 
    ) internal virtual returns (bool success, uint256 actualAmount) {
        
        
        return (token.trySafeTransfer(prefunder, prefundAmount - actualAmount_), actualAmount_);
    }

    
    function _fetchDetails(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) internal view virtual returns (uint256 validationData, IERC20 token, uint256 tokenPerNative);

    
    function _postOpCost() internal view virtual returns (uint256) {
        return 30_000;
    }

    
    function _postOpGasBudget(PackedUserOperation calldata ) internal view virtual returns (uint256) {
        return _postOpCost();
    }

    
    function _postOpGasPenalty(uint256 unusedPostOpGas) internal view virtual returns (uint256) {
        return unusedPostOpGas / 10;
    }

    
    function _tokenPerNativeDenominator() internal view virtual returns (uint256) {
        return 1e18;
    }

    
    function _minTokensPerNative() internal view virtual returns (uint256) {
        return 0;
    }

    
    function _erc20Cost(uint256 nativeCost, uint256 tokenPerNative) internal view virtual returns (uint256) {
        uint256 denominator = _tokenPerNativeDenominator();
        (uint256 high, ) = nativeCost.mul512(tokenPerNative);
        
        return
            high < denominator
                ? nativeCost.mulDiv(tokenPerNative, denominator).saturatingAdd(
                    (mulmod(nativeCost, tokenPerNative, denominator) > 0).toUint()
                )
                : type(uint256).max;
    }

    
    function _withdrawTokens(IERC20 token, address recipient, uint256 amount) internal virtual {
        if (amount == type(uint256).max) amount = token.balanceOf(address(this));
        token.safeTransfer(recipient, amount);
    }
}
