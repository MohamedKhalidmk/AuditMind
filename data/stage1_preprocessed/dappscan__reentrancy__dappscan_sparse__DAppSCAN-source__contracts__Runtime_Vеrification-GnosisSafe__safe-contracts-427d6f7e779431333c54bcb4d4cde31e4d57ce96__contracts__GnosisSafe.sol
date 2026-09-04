pragma solidity ^0.5.0;
import "./base/BaseSafe.sol";
import "./common/MasterCopy.sol";
import "./common/SignatureDecoder.sol";
import "./common/SecuredTokenTransfer.sol";
import "./interfaces/ISignatureValidator.sol";
import "./external/SafeMath.sol";





contract GnosisSafe is MasterCopy, BaseSafe, SignatureDecoder, SecuredTokenTransfer, ISignatureValidator {

    using SafeMath for uint256;

    string public constant NAME = "Gnosis Safe";
    string public constant VERSION = "0.1.0";

    
    
    
    bytes32 public constant DOMAIN_SEPARATOR_TYPEHASH = 0x035aff83d86937d35b32e04f0ddc6ff469290eef2f1b692d8a815c89404d4749;

    
    
    
    bytes32 public constant SAFE_TX_TYPEHASH = 0x14d461bc7412367e924637b363c7bf29b8f47e2f84869f4426e5633d8af47b20;

    
    
    
    bytes32 public constant SAFE_MSG_TYPEHASH = 0x60b3cbf8b4a223d68d641b3b6ddf9a298e7f33710cf3d3a9d1146b5a6150fbca;

    event ExecutionFailed(bytes32 txHash);

    uint256 public nonce;
    bytes32 public domainSeparator;
    
    mapping(bytes32 => uint256) public signedMessages;
    
    mapping(address => mapping(bytes32 => uint256)) public approvedHashes;

    
    
    
    
    
    function setup(address[] calldata _owners, uint256 _threshold, address to, bytes calldata data)
        external
    {
        require(domainSeparator == 0, "Domain Separator already set!");
        domainSeparator = keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, this));
        setupSafe(_owners, _threshold, to, data);
    }

    
    
    
    
    
    
    
    
    
    
    
    
    
    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 dataGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes calldata signatures
    )
        external
        returns (bool success)
    {
        uint256 startGas = gasleft();
        bytes memory txHashData = encodeTransactionData(
            to, value, data, operation, 
            safeTxGas, dataGas, gasPrice, gasToken, refundReceiver, 
            nonce
        );
        require(checkSignatures(keccak256(txHashData), txHashData, signatures, true), "Invalid signatures provided");
        
        
        nonce++;
        require(gasleft() >= safeTxGas, "Not enough gas to execute safe transaction");
        
        success = execute(to, value, data, operation, safeTxGas == 0 && gasPrice == 0 ? gasleft() : safeTxGas);
        if (!success) {
            emit ExecutionFailed(keccak256(txHashData));
        }

        
        if (gasPrice > 0) {
            handlePayment(startGas, dataGas, gasPrice, gasToken, refundReceiver);
        }
    }

    function handlePayment(
        uint256 startGas,
        uint256 dataGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver
    )
        private
    {
        uint256 amount = startGas.sub(gasleft()).add(dataGas).mul(gasPrice);
        
        address payable receiver = refundReceiver == address(0) ? tx.origin : refundReceiver;
        if (gasToken == address(0)) {
            
            require(receiver.send(amount), "Could not pay gas costs with ether");
        } else {
            require(transferToken(gasToken, receiver, amount), "Could not pay gas costs with token");
        }
    }

    
    function checkSignatures(bytes32 dataHash, bytes memory data, bytes memory signatures, bool consumeHash)
        internal
        returns (bool)
    {
        
        
        if (signatures.length < threshold * 65) {
            return false;
        }
        
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < threshold; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            
            if (v == 0) {
                
                currentOwner = address(uint256(r));
                bytes memory contractSignature;
                
                assembly {
                    
                    contractSignature := add(add(signatures, s), 0x20)
                }
                if (!ISignatureValidator(currentOwner).isValidSignature(data, contractSignature)) {
                    return false;
                }
            
            } else if (v == 1) {
                
                currentOwner = address(uint256(r));
                
                if (msg.sender != currentOwner && approvedHashes[currentOwner][dataHash] == 0) {
                    return false;
                }
                
                if (consumeHash && msg.sender != currentOwner) {
                    approvedHashes[currentOwner][dataHash] = 0;
                }
            } else {
                
                currentOwner = ecrecover(dataHash, v, r, s);
            }
            if (currentOwner <= lastOwner || owners[currentOwner] == address(0)) {
                return false;
            }
            lastOwner = currentOwner;
        }
        return true;
    }

    
    
    
    
    
    
    
    
    
    
    
    function requiredTxGas(address to, uint256 value, bytes calldata data, Enum.Operation operation)
        external
        authorized
        returns (uint256)
    {
        uint256 startGas = gasleft();
        
        
        require(execute(to, value, data, operation, gasleft()));
        uint256 requiredGas = startGas - gasleft();
        
        revert(string(abi.encodePacked(requiredGas)));
    }

    
    function approveHash(bytes32 hashToApprove)
        external
    {
        require(owners[msg.sender] != address(0), "Only owners can approve a hash");
        approvedHashes[msg.sender][hashToApprove] = 1;
    }

     
    function signMessage(bytes calldata _data) 
        external
        authorized
    {
        signedMessages[getMessageHash(_data)] = 1;
    }

     
    function isValidSignature(bytes calldata _data, bytes calldata _signature)
        external
        returns (bool isValid)
    {
        bytes32 messageHash = getMessageHash(_data);
        if (_signature.length == 0) {
            isValid = signedMessages[messageHash] != 0;
        } else {
            
            isValid = checkSignatures(messageHash, _data, _signature, false);
        }
    }

    
    
    
    function getMessageHash(
        bytes memory message
    )
        public
        view
        returns (bytes32)
    {
        bytes32 safeMessageHash = keccak256(
            abi.encode(SAFE_MSG_TYPEHASH, keccak256(message))
        );
        return keccak256(
            abi.encodePacked(byte(0x19), byte(0x01), domainSeparator, safeMessageHash)
        );
    }

    
    
    
    
    
    
    
    
    
    
    
    
    function encodeTransactionData(
        address to, 
        uint256 value, 
        bytes memory data, 
        Enum.Operation operation, 
        uint256 safeTxGas, 
        uint256 dataGas, 
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    )
        public
        view
        returns (bytes memory)
    {
        bytes32 safeTxHash = keccak256(
            abi.encode(SAFE_TX_TYPEHASH, to, value, keccak256(data), operation, safeTxGas, dataGas, gasPrice, gasToken, refundReceiver, _nonce)
        );
        return abi.encodePacked(byte(0x19), byte(0x01), domainSeparator, safeTxHash);
    }

    
    
    
    
    
    
    
    
    
    
    
    
    function getTransactionHash(
        address to, 
        uint256 value, 
        bytes memory data, 
        Enum.Operation operation, 
        uint256 safeTxGas, 
        uint256 dataGas, 
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    )
        public
        view
        returns (bytes32)
    {
        return keccak256(encodeTransactionData(to, value, data, operation, safeTxGas, dataGas, gasPrice, gasToken, refundReceiver, _nonce));
    }
}
