
pragma solidity ^0.8.0;

  

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Recoverable.sol";
import "./Generatable.sol";
import "./Array.sol";


struct Fee {
    uint128 numerator;
    uint128 denominator;
}

struct PendingPeriod {
    uint128 repeat;
    uint128 period;
}

struct PendingAmount {
    uint32 createdAt;
    uint112 fullAmount;
    uint112 claimedAmount;
    PendingPeriod pendingPeriod;
}


contract SamuraiLegendsStaking is Ownable, Pausable, Generatable, Recoverable {
    using Array for uint[];

    IERC20 private immutable _token;

    uint160 public rewardRate;
    uint32 public rewardDuration = 12 weeks;
    
    uint32 private _rewardUpdatedAt = uint32(block.timestamp);
    uint32 public rewardFinishedAt;

    uint private _totalStake;
    mapping(address => uint) private _userStake;
    
    uint128 private _rewardPerToken;
    uint128 private _lastRewardPerTokenPaid;
    mapping(address => uint) private _userRewardPerTokenPaid;

    Fee public fee = Fee(0, 1000);

    PendingPeriod public pendingPeriod = PendingPeriod({ repeat: 4, period: 7 days });
    mapping(address => uint[]) private _userPendingIds;
    mapping(address => mapping(uint => PendingAmount)) private _userPending;

    
    constructor(IERC20 token) {
        _token = token;
    }

    
    function totalStake() public view returns (uint) {
        return _totalStake + _earned(_totalStake, _lastRewardPerTokenPaid);
    }

    
    function userStake(address account) public view returns (uint) {
        return _userStake[account] + earned(account);
    }

    
    function userPending(address account, uint index) public view returns (PendingAmount memory) {
        uint id = _userPendingIds[account][index];
        return _userPending[account][id];
    }

    
    function userClaimablePendingPercentage(address account, uint index) public view returns (uint) {
        PendingAmount memory pendingAmount = userPending(account, index);
        uint n = getClaimablePendingPortion(pendingAmount);
        return n >= pendingAmount.pendingPeriod.repeat ? 100 * 1e9 : (n * 100 * 1e9) / pendingAmount.pendingPeriod.repeat;
    }

    
    function userPendingIds(address account) public view returns (uint[] memory) {
        return _userPendingIds[account];
    }

    
    function lastTimeRewardActiveAt() public view returns (uint) {
    
        return rewardFinishedAt > block.timestamp ? block.timestamp : rewardFinishedAt;
    }

    
    function rewardPerToken() public view returns (uint) {
        if (_totalStake == 0) {
            return _rewardPerToken;
        }

        return _rewardPerToken + ((lastTimeRewardActiveAt() - _rewardUpdatedAt) * rewardRate * 1e9) / _totalStake;
    }

    
    function totalDurationReward() public view returns (uint) {
        return rewardRate * rewardDuration;
    }

    
    function earned(address account) private view returns (uint) {
        return _earned(_userStake[account], _userRewardPerTokenPaid[account]);
    }

    
    function _earned(uint stakeAmount, uint rewardPerTokenPaid) internal view returns (uint) {
        uint rewardPerTokenDiff = rewardPerToken() - rewardPerTokenPaid;
        return (stakeAmount * rewardPerTokenDiff) / 1e9;
    }

    
    modifier updateReward(address account) {
        _rewardPerToken = uint128(rewardPerToken());
        _rewardUpdatedAt = uint32(lastTimeRewardActiveAt());
        
        
        if (account != address(0)) {
            uint reward = earned(account);

            _userRewardPerTokenPaid[account] = _rewardPerToken;
            _lastRewardPerTokenPaid = _rewardPerToken;

            _userStake[account] += reward;
            _totalStake += reward;
        }
        _;
    }

    
    function stake(uint amount) public whenNotPaused updateReward(msg.sender) {
        
        require(amount > 0, "Invalid input amount.");

        
        _totalStake += amount;
        _userStake[msg.sender] += amount;

        
        require(_token.transferFrom(msg.sender, address(this), amount), "Transfer failed.");

        emit Staked(msg.sender, amount);
    }

    
    function createPending(uint amount) internal {
        uint id = unique();
        _userPendingIds[msg.sender].push(id);
        _userPending[msg.sender][id] = PendingAmount({  
    
            createdAt: uint32(block.timestamp), 
            fullAmount: uint112(amount), 
            claimedAmount: 0,
            pendingPeriod: pendingPeriod
        });

        emit PendingCreated(msg.sender, block.timestamp, amount);
    }

    
    function cancelPending(uint index) external whenNotPaused updateReward(msg.sender) {
        PendingAmount memory pendingAmount = userPending(msg.sender, index);
        uint amount = pendingAmount.fullAmount - pendingAmount.claimedAmount;
        deletePending(index);

        
        _totalStake += amount;
        _userStake[msg.sender] += amount;

        emit PendingCanceled(msg.sender, pendingAmount.createdAt, pendingAmount.fullAmount);
    }

    
    function deletePending(uint index) internal {
        uint[] storage ids = _userPendingIds[msg.sender];
        uint id = ids[index];
        ids.remove(index);
        delete _userPending[msg.sender][id];
    }

    
    function _withdraw(uint amount) internal {
        
        _totalStake -= amount;
        _userStake[msg.sender] -= amount;

        createPending(amount);

        emit Withdrawn(msg.sender, amount);
    }

    
    function withdraw(uint amount) external updateReward(msg.sender) {
        
        require(_userStake[msg.sender] > 0, "User has no active stake.");
        require(amount > 0 && _userStake[msg.sender] >= amount, "Invalid input amount.");

        
        _withdraw(amount);
    }

    
    function withdrawAll() external updateReward(msg.sender) {
        
        require(_userStake[msg.sender] > 0, "User has no active stake.");

        
        _withdraw(_userStake[msg.sender]);
    }

    
    function getClaimablePendingPortion(PendingAmount memory pendingAmount) private view returns (uint) {
        
        return (block.timestamp - pendingAmount.createdAt) / pendingAmount.pendingPeriod.period; 
    }

    
    function setFee(uint128 numerator, uint128 denominator) external onlyOwner {
        require(denominator != 0, "Denominator must not equal 0.");
        fee = Fee(numerator, denominator);
        emit FeeUpdated(numerator, denominator);
    }

    
    function claim(uint index) external {
        
        uint id = _userPendingIds[msg.sender][index];
        PendingAmount storage pendingAmount = _userPending[msg.sender][id];

        uint n = getClaimablePendingPortion(pendingAmount);
        require(n != 0, "Claim is still pending.");

        uint amount;
        
        if (n >= pendingAmount.pendingPeriod.repeat) {
            amount = pendingAmount.fullAmount - pendingAmount.claimedAmount;
        } else {
            uint percentage = (n * 1e9) / pendingAmount.pendingPeriod.repeat;
            amount = (pendingAmount.fullAmount * percentage) / 1e9 - pendingAmount.claimedAmount;
        }
        
        
        
        if (n >= pendingAmount.pendingPeriod.repeat) {
            uint createdAt = pendingAmount.createdAt;
            uint fullAmount = pendingAmount.fullAmount;
            deletePending(index);
            emit PendingFinished(msg.sender, createdAt, fullAmount);
        } 
        
        else {
            pendingAmount.claimedAmount += uint112(amount);
            emit PendingUpdated(msg.sender, pendingAmount.createdAt, pendingAmount.fullAmount);
        }
        
        
        uint feeAmount = amount * fee.numerator / fee.denominator;
        require(_token.transfer(msg.sender, amount - feeAmount), "Transfer failed.");

        emit Claimed(msg.sender, amount);
    }

    
    function addReward(uint _reward) external onlyOwner updateReward(address(0)) {
        
        require(_reward > 0, "Invalid input amount.");

        
        if (block.timestamp > rewardFinishedAt) { 
            rewardRate = uint160(_reward / rewardDuration);
        } else {
            uint remainingReward = rewardRate * (rewardFinishedAt - block.timestamp);
            rewardRate = uint160((remainingReward + _reward) / rewardDuration);
        }

        
        _rewardUpdatedAt = uint32(block.timestamp);
        rewardFinishedAt = uint32(block.timestamp + rewardDuration);

        
        require(_token.transferFrom(owner(), address(this), _reward), "Transfer failed.");

        emit RewardAdded(_reward);
    }

    
    function decreaseReward(uint _reward) external onlyOwner updateReward(address(0)) {
        
        require(_reward > 0, "Invalid input amount.");
        require(block.timestamp <= rewardFinishedAt, "Reward duration finished.");

        uint remainingReward = rewardRate * (rewardFinishedAt - block.timestamp);
        require(remainingReward > _reward, "Invalid input amount.");

        
        rewardRate = uint160((remainingReward - _reward) / (rewardFinishedAt - block.timestamp));
        _rewardUpdatedAt = uint32(block.timestamp);

        
        require(_token.transfer(owner(), _reward), "Transfer failed.");

        emit RewardDecreased(_reward);
    }

    
    function resetReward() external onlyOwner updateReward(address(0)) {
        if (rewardFinishedAt <= block.timestamp) {
            rewardRate = 0;
            _rewardUpdatedAt = uint32(block.timestamp);
            rewardFinishedAt = uint32(block.timestamp);
        } else  {
            
            uint remainingReward = rewardRate * (rewardFinishedAt - block.timestamp);

            
            rewardRate = 0;
            _rewardUpdatedAt = uint32(block.timestamp);
            rewardFinishedAt = uint32(block.timestamp);

            
            require(_token.transfer(owner(), remainingReward), "Transfer failed.");
        }

        emit RewardReseted();
    }

    
    function updateRewardDuration(uint32 _rewardDuration) external onlyOwner {
        require(block.timestamp > rewardFinishedAt, "Reward duration must be finalized.");

        rewardDuration = _rewardDuration;

        emit RewardDurationUpdated(_rewardDuration);
    }

    
    function updatePendingPeriod(uint128 repeat, uint128 period) external onlyOwner {
        pendingPeriod = PendingPeriod(repeat, period);
        emit PendingPeriodUpdated(repeat, period);
    }

    
    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    
    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    event Staked(address indexed account, uint amount);
    event PendingCreated(address indexed account, uint createdAt, uint amount);
    event PendingUpdated(address indexed account, uint createdAt, uint amount);
    event PendingFinished(address indexed account, uint createdAt, uint amount);
    event PendingCanceled(address indexed account, uint createdAt, uint amount);
    event Withdrawn(address indexed account, uint amount);
    event Claimed(address indexed account, uint amount);
    event RewardAdded(uint amount);
    event RewardDecreased(uint amount);
    event RewardReseted();
    event RewardDurationUpdated(uint duration);
    event PendingPeriodUpdated(uint repeat, uint period);
    event FeeUpdated(uint numerator, uint denominator);
}