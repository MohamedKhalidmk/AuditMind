


pragma solidity ^0.8.20;

import {ERC4337Utils} from "../utils/ERC4337Utils.sol";
import {IEntryPoint, IPaymaster, PackedUserOperation} from "../../interfaces/IERC4337.sol";


abstract contract Paymaster is IPaymaster {
    
    error PaymasterUnauthorized(address sender);

    
    modifier onlyEntryPoint() {
        _checkEntryPoint();
        _;
    }

    
    function entryPoint() public view virtual returns (IEntryPoint) {
        return ERC4337Utils.ENTRYPOINT_V09;
    }

    
    function validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) public virtual onlyEntryPoint returns (bytes memory context, uint256 validationData) {
        return _validatePaymasterUserOp(userOp, userOpHash, maxCost);
    }

    
    function postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost,
        uint256 actualUserOpFeePerGas
    ) public virtual onlyEntryPoint {
        _postOp(mode, context, actualGasCost, actualUserOpFeePerGas);
    }

    
    function _validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 requiredPreFund
    ) internal virtual returns (bytes memory context, uint256 validationData);

    
    function _postOp(
        PostOpMode ,
        bytes calldata ,
        uint256 ,
        uint256 
    ) internal virtual {}

    
    function _checkEntryPoint() internal view virtual {
        address sender = msg.sender;
        if (sender != address(entryPoint())) {
            revert PaymasterUnauthorized(sender);
        }
    }

    
    function _deposit(uint256 value) internal virtual {
        entryPoint().depositTo{value: value}(address(this));
    }

    
    function _withdraw(address payable to, uint256 value) internal virtual {
        entryPoint().withdrawTo(to, value);
    }

    
    function _addStake(uint256 value, uint32 unstakeDelaySec) internal virtual {
        entryPoint().addStake{value: value}(unstakeDelaySec);
    }

    
    function _unlockStake() internal virtual {
        entryPoint().unlockStake();
    }

    
    function _withdrawStake(address payable to) internal virtual {
        entryPoint().withdrawStake(to);
    }
}
