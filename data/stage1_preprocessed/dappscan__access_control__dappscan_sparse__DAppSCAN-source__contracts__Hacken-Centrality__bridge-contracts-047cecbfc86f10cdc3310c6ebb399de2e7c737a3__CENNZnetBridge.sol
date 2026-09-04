
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";


struct CENNZnetEventProof {
    
    uint256 eventId;
    
    uint32 validatorSetId;
    
    
    
    uint8[] v;
    
    bytes32[] r;
    
    bytes32[] s;
}


contract CENNZnetBridge is Ownable {
    
    
    
    mapping(uint => address[]) public validators;
    
    uint32 public activeValidatorSetId;
    
    
    
    mapping(uint => bool) public eventIds;
    
    
    uint public verificationFee = 1e15;
    
    uint public thresholdPercent = 61;
    
    uint public proofTTL = 3;
    
    bool public active = true;

    event SetValidators(address[], uint reward, uint32 validatorSetId);

    
    
    
    
    
    
    
    
    
    
    function verifyMessage(bytes memory message, CENNZnetEventProof memory proof) payable external {
        require(active, "bridge inactive");
        uint256 eventId = proof.eventId;
        require(!eventIds[eventId], "eventId replayed");
        require(msg.value >= verificationFee || msg.sender == address(this), "must supply verification fee");
        uint32 validatorSetId = proof.validatorSetId;
        require(validatorSetId <= activeValidatorSetId, "future validator set");
        require(activeValidatorSetId - validatorSetId <= proofTTL, "expired proof");

        address[] memory _validators = validators[validatorSetId];

        
        require(_validators.length > 0, "invalid validator set");

        bytes32 digest = keccak256(message);
        uint acceptanceTreshold = (_validators.length * thresholdPercent / 100);
        uint witnessCount;
        bytes32 ommited;

        for (uint i; i < _validators.length; i++) {
            
            if(proof.r[i] != ommited) {
                
                require(_validators[i] == ecrecover(digest, proof.v[i], proof.r[i], proof.s[i]), "signature invalid");
                witnessCount += 1;
                
                if(witnessCount >= acceptanceTreshold) {
                    break;
                }
            }
        }

        require(witnessCount >= acceptanceTreshold, "not enough signatures");
        eventIds[eventId] = true;
    }

    
    
    
    
    
    

    function setValidators(
        address[] memory newValidators,
        uint32 newValidatorSetId,
        CENNZnetEventProof memory proof
    ) external payable {
        require(newValidators.length > 0, "empty validator set");
        require(newValidatorSetId > activeValidatorSetId , "validator set id replayed");

        bytes memory message = abi.encode(newValidators, newValidatorSetId, proof.validatorSetId, proof.eventId);
        this.verifyMessage(message, proof);

        
        validators[newValidatorSetId] = newValidators;
        activeValidatorSetId = newValidatorSetId;

        
        uint reward = address(this).balance;
        (bool sent, ) = msg.sender.call{value: reward}("");
        require(sent, "Failed to send Ether");

        emit SetValidators(newValidators, reward, newValidatorSetId);
    }

    

    
    function forceActiveValidatorSet(address[] memory _validators, uint32 validatorSetId) external onlyOwner {
        require(_validators.length > 0, "empty validator set");
        require(validatorSetId >= activeValidatorSetId, "set is historic");
        validators[validatorSetId] = _validators;
        activeValidatorSetId = validatorSetId;
    }

    
    
    function forceHistoricValidatorSet(address[] memory _validators, uint32 validatorSetId) external onlyOwner {
        require(_validators.length > 0, "empty validator set");
        require(validatorSetId + proofTTL > activeValidatorSetId, "set is inactive");
        validators[validatorSetId] = _validators;
    }

    
    function setProofTTL(uint newTTL) external onlyOwner {
        proofTTL = newTTL;
    }

    
    function setVerificationFee(uint newFee) external onlyOwner {
        verificationFee = newFee;
    }

    
    function setThreshold(uint newThresholdPercent) external onlyOwner {
        thresholdPercent = newThresholdPercent;
    }

    
    function setActive(bool active_) external onlyOwner {
        active = active_;
    }
}
