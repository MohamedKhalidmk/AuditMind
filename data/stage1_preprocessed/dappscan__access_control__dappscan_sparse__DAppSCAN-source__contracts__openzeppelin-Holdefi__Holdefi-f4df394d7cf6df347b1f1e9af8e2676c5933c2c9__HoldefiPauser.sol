pragma solidity ^0.5.16;

import "./Ownable.sol";


contract HoldefiPauser is Ownable {    
    address public pauser;

     
     
     
     
     
     
     
     
    
    uint constant functionsNum = 8;
    uint[8] public paused;

    uint public pauseDuration = 2592000;

     
    constructor (address newOwnerChanger) Ownable(newOwnerChanger) public {
    }

    
    modifier onlyPausers() {
        require(msg.sender == owner || msg.sender == pauser , 'Sender should be Owner or Pauser');
        _;
    }
    
    
    modifier whenNotPaused(uint index) {
        require(!isPause(index), "Pausable: paused");
        _;
    }

    
    modifier whenPaused(uint index) {
        require(isPause(index), "Pausable: not paused");
        _;
    }

    function isPause(uint index) public view returns(bool res) {
        if (block.timestamp - paused[index] >= pauseDuration) {
            res = false;
        }
        else {
            res = true;
        }
    }
    
    
    function pause(uint index) public onlyPausers {
        paused[index] = block.timestamp;
    }

    
    function unpause(uint index) public onlyOwner {
        paused[index] = 0;
    }

    
    function batchPause(bool[8] memory newPaused) public onlyPausers {
        for (uint i=0; i<functionsNum; i++) {
            if (newPaused[i] == true){
                pause(i);
            }
        }
    }

    
    function batchUnpause(bool[8] memory newUnpaused) public onlyOwner {
        for (uint i=0; i<functionsNum; i++) {
            if (newUnpaused[i] == true){
                unpause(i);
            }
        }
    }
    
    function setPauser(address newPauser) external onlyOwner {
        pauser = newPauser;
    }

    function setPauseDuration(uint newPauseDuration) external onlyOwner {
        pauseDuration = newPauseDuration;
    }
}