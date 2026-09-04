


pragma solidity ^0.8.2;

import "./Ania.sol";

contract AniaStake {
    string public name = "Arkania Protocol Launchpad";
    ArkaniaProtocol public aniaToken;

    
    address public owner;

    
    uint256 public apy = 100;

    
    uint256 public totalStaked = 0;

    
    struct Stake{
        address user;
        uint256 amount;
        uint256 since;
    }

    
    struct Staker{
        address user;
        Stake address_stake;
    }

    
    Staker[] internal stakers;

    
    mapping(address => uint256) internal stakes;

    constructor(ArkaniaProtocol _aniaToken) payable {
        aniaToken = _aniaToken;

        
        owner = msg.sender;

        
        stakers.push();
    }

    
    function calculateStakeReward(Stake memory _current_stake) internal view returns(uint256) {
        return (_current_stake.amount * apy / 100) * (block.timestamp - _current_stake.since) / (365 days);
    }

    
    function _addStaker(address staker) internal returns (uint256){
        
        stakers.push();
        
        uint256 userIndex = stakers.length - 1;
        
        stakers[userIndex].user = staker;
        
        stakes[staker] = userIndex;
        return userIndex;
    }

    
    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    }

    
    function stakeTokens(uint256 _amount) public {
        
        require(_amount > 0, "amount cannot be 0");

        
        uint256 index = stakes[msg.sender];
        
        uint256 timestamp = block.timestamp;

        uint256 reward = 0;
        
        if (index == 0){
            
            
            
            index = _addStaker(msg.sender);
        } else {
            reward = calculateStakeReward(stakers[index].address_stake);
        }

        uint256 newStake = stakers[index].address_stake.amount + _amount + reward;

        
        
        stakers[index].address_stake = Stake(msg.sender, newStake, timestamp);
        totalStaked += newStake;

        
        aniaToken.transferFrom(msg.sender, address(this), _amount);
    }

    
    function unstakeTokens(uint256 _amount) public {

        uint256 index = stakes[msg.sender];

        
        uint256 userStakes = stakers[index].address_stake.amount;

        
        require(userStakes > 0, "amount has to be more than 0");

        
        uint256 reward = calculateStakeReward(stakers[index].address_stake);

        
        uint256 stakedWithRewards = userStakes + reward;
        require(_amount <= stakedWithRewards, "amount has to be less or equal than current stakes with rewards");
        aniaToken.transfer(msg.sender, _amount);

        
        stakers[index].address_stake = Stake(msg.sender, userStakes + reward - _amount, block.timestamp);

        
        if (userStakes < _amount) {
            totalStaked -= userStakes;  
        } else {
            totalStaked -= _amount;
        }
    }

    
    function hasRewards() public view returns(uint256) {
        
        uint256 index = stakes[msg.sender];
        return calculateStakeReward(stakers[index].address_stake);
    }

    
    function hasStakeWithRewards(address _address) public view returns(uint256) {
        
        uint256 index = stakes[_address];

        if (stakers[index].user != _address) {
            return 0;
        }

        
        uint256 balance = stakers[index].address_stake.amount;

        if (index != 0) {
            balance += calculateStakeReward(stakers[index].address_stake);
        }
        return balance;
    }

    
    function redistributeRewards(address[] calldata users) public {
        
        require(msg.sender == owner, "Only contract creator can redistribute");
        
        for (uint256 i = 0; i < users.length; i++) {
            uint256 index = stakes[users[i]];
            uint256 reward = calculateStakeReward(stakers[index].address_stake);

            
            stakers[index].address_stake = Stake(stakers[index].user, stakers[index].address_stake.amount + reward, block.timestamp);

            
            totalStaked += reward;
        }
    }

    
    function changeAPY(uint256 _value, address[] calldata users) public {
        
        require(msg.sender == owner, "Only contract creator can change APY");
        require(
            _value > 0,
            "APY value has to be more than 0, try 100 for (0.100% daily) instead"
        );
        redistributeRewards(users);
        apy = _value;
    }
}
