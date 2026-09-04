



pragma solidity ^0.6.0;

interface IBEP20 {
    
    function totalSupply() external view returns (uint256);

    
    function decimals() external view returns (uint8);

    
    function symbol() external view returns (string memory);

    
    function name() external view returns (string memory);

    
    function getOwner() external view returns (address);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address _owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




pragma solidity ^0.6.0;
interface IBEP20Mintable is IBEP20 {
    function mint(address to, uint256 amount) external;
    function transferOwnership(address newOwner) external;
}





pragma solidity >=0.6.0 <0.8.0;


library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        
        
        
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}




pragma solidity >=0.6.2 <0.8.0;


library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        

        uint256 size;
        
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                

                
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}




pragma solidity ^0.6.0;

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        
        
        
        
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        
        
        

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            
            
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}





pragma solidity >=0.6.0 <0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}




pragma solidity >=0.6.0 <0.8.0;


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}





pragma solidity >=0.6.0 <0.8.0;


abstract contract ReentrancyGuard {
    
    
    
    
    

    
    
    
    
    
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    
    modifier nonReentrant() {
        
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        
        _status = _ENTERED;

        _;

        
        
        _status = _NOT_ENTERED;
    }
}





pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract Reserve is Ownable {
    function safeTransfer(
        IBEP20 rewardToken,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        uint256 tokenBal = rewardToken.balanceOf(address(this));
        if (_amount > tokenBal) {
            rewardToken.transfer(_to, tokenBal);
        } else {
            rewardToken.transfer(_to, _amount);
        }
    }
}

contract BitBookStaking is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    struct WithdrawFeeInterval {
        uint256 day;
        uint256 fee;
    }

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 rewardLockedUp;
        uint256 nextHarvestUntil;
        uint256 depositTimestamp;
    }

    struct PoolInfo {
        IBEP20 stakedToken;
        IBEP20 rewardToken;
        uint256 stakedAmount;
        uint256 rewardSupply;
        uint256 tokenPerBlock;
        uint256 lastRewardBlock;
        uint256 accTokenPerShare;
        uint16 depositFeeBP;
        uint256 minDeposit;
        uint256 harvestInterval;
        bool lockDeposit;
    }

    Reserve public rewardReserve;
    uint256 public constant BONUS_MULTIPLIER = 1;
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 14 days;

    mapping(address => mapping(address => bool)) internal poolExists;
    mapping(uint256 => uint256) public rewardDistributions;

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(uint256 => WithdrawFeeInterval[]) public withdrawFee;
    uint256 public startBlock;
    bool public paused = true;
    bool public initialized = false;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);
    event PoolUpdated(uint256 tokenPerBlock, uint256 depositFee, uint256 minDeposit, uint256 harvestInterval);
    event RewardTokenDeposited(address depositer, uint256 pid, uint256 amount);
    event AdminEmergencyWithdraw(uint256 pid, uint256 currentRewardBalance, uint256 accTokenPerShare, uint256 tokenPerBlock, uint256 lastRewardBlock);
    event PoolPausedUpdated(bool paused);
    event DepositLocked(uint256 pid, bool depositLocked);

    constructor() public {
        startBlock = 0;
        rewardReserve = new Reserve();
        WithdrawFeeInterval[] memory _withdrawFee = new WithdrawFeeInterval[](5);
        _withdrawFee[0] = WithdrawFeeInterval(3 days, 50);
        _withdrawFee[1] = WithdrawFeeInterval(10 days, 25);
        _withdrawFee[2] = WithdrawFeeInterval(30 days, 15);
        _withdrawFee[3] = WithdrawFeeInterval(90 days, 5);
        add(108e6, IBEP20(0xD48474E7444727bF500a32D5AbE01943f3A59A64), IBEP20(0xD48474E7444727bF500a32D5AbE01943f3A59A64), 0, 0, 0, _withdrawFee);
    }

    function initialize() external onlyOwner {
        require(!initialized, "BITBOOK_STAKING: Staking already started!");
        initialized = true;
        paused = false;
        startBlock = block.number;
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            poolInfo[pid].lastRewardBlock = startBlock;
        }
    }

    function getWithdrawFeeIntervals(uint256 poolId) external view returns (WithdrawFeeInterval[] memory) {
        return withdrawFee[poolId];
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function add(
        uint256 _tokenPerBlock,
        IBEP20 _stakedToken,
        IBEP20 _rewardToken,
        uint16 _depositFeeBP,
        uint256 _minDeposit,
        uint256 _harvestInterval,
        WithdrawFeeInterval[] memory withdrawFeeIntervals
    ) public onlyOwner {
        require(address(_stakedToken) != address(0), "BITBOOK_STAKING: Invalid Staked token address");
        require(address(_rewardToken) != address(0), "BITBOOK_STAKING: Invalid Reward token address");
        require(poolInfo.length <= 1000, "BITBOOK_STAKING: Pool Length Full!");
        require(!poolExists[address(_stakedToken)][address(_rewardToken)], "BITBOOK_STAKING: Pool Already Exists!");
        require(_depositFeeBP <= 10000, "BITBOOK_STAKING: invalid deposit fee basis points");
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "BITBOOK_STAKING: invalid harvest interval");

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        poolInfo.push(
            PoolInfo({
                stakedToken: _stakedToken,
                rewardToken: _rewardToken,
                stakedAmount: 0,
                rewardSupply: 0,
                tokenPerBlock: _tokenPerBlock,
                lastRewardBlock: lastRewardBlock,
                accTokenPerShare: 0,
                depositFeeBP: _depositFeeBP,
                minDeposit: _minDeposit,
                harvestInterval: _harvestInterval,
                lockDeposit: false
            })
        );
        uint256 length = withdrawFeeIntervals.length;
        for (uint256 i = 0; i < length; i++) {
            withdrawFee[poolInfo.length - 1].push(withdrawFeeIntervals[i]);
        }
        poolExists[address(_stakedToken)][address(_rewardToken)] = true;
    }

    function set(
        uint256 _pid,
        uint256 _tokenPerBlock,
        uint16 _depositFeeBP,
        uint256 _minDeposit,
        uint256 _harvestInterval
    ) external onlyOwner {
        require(_depositFeeBP <= 10000, "BITBOOK_STAKING: invalid deposit fee basis points");
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "BITBOOK_STAKING: invalid harvest interval");

        poolInfo[_pid].tokenPerBlock = _tokenPerBlock;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].minDeposit = _minDeposit;
        poolInfo[_pid].harvestInterval = _harvestInterval;

        emit PoolUpdated(_tokenPerBlock, _depositFeeBP, _minDeposit, _harvestInterval);
    }

    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    function pendingToken(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        if (
            block.number > pool.lastRewardBlock &&
            pool.stakedAmount != 0 &&
            pool.rewardToken.balanceOf(address(this)) > 0
        ) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward = multiplier.mul(pool.tokenPerBlock);
            accTokenPerShare = accTokenPerShare.add(tokenReward.mul(1e12).div(pool.stakedAmount));
        }
        return user.amount.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);
    }

    function canHarvest(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return user.amount != 0 && block.timestamp >= user.nextHarvestUntil;
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 tokenBalance = pool.stakedAmount;
        if (tokenBalance == 0 || pool.tokenPerBlock == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward = multiplier.mul(pool.tokenPerBlock);
        uint256 rewardTokenSupply = pool.rewardSupply;
        uint256 reward = tokenReward > rewardTokenSupply ? rewardTokenSupply : tokenReward;
        if (reward > 0) {
            pool.rewardSupply -= reward;
            pool.accTokenPerShare = pool.accTokenPerShare.add(reward.mul(1e12).div(tokenBalance));
        }
        pool.lastRewardBlock = block.number;
    }

    function depositRewardToken(uint256 poolId, uint256 amount) external {
        PoolInfo storage _poolInfo = poolInfo[poolId];
        uint256 initialBalance = _poolInfo.rewardToken.balanceOf(address(rewardReserve));
        _poolInfo.rewardToken.safeTransferFrom(msg.sender, address(rewardReserve), amount);
        uint256 finalBalance = _poolInfo.rewardToken.balanceOf(address(rewardReserve));
        _poolInfo.rewardSupply += finalBalance.sub(initialBalance);

        emit RewardTokenDeposited(msg.sender, poolId, amount);
    }

    function deposit(uint256 _pid, uint256 _amount) external {
        require(!paused, "BITBOOK_STAKING: Paused!");
        PoolInfo storage pool = poolInfo[_pid];
        require(!pool.lockDeposit, "BITBOOK_STAKING: Deposit Locked!");
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        payOrLockupPendingToken(_pid);
        if (_amount > 0) {
            require(_amount >= poolInfo[_pid].minDeposit, "BITBOOK_STAKING: Not Enough Required Staking Tokens!");
            user.depositTimestamp = block.timestamp;
            uint256 initialBalance = pool.stakedToken.balanceOf(address(this));
            pool.stakedToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 finalBalance = pool.stakedToken.balanceOf(address(this));
            uint256 delta = finalBalance.sub(initialBalance);
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.stakedToken.safeTransfer(owner(), depositFee);
                user.amount = user.amount.add(delta).sub(depositFee);
                pool.stakedAmount = pool.stakedAmount.add(delta).sub(depositFee);
            } else {
                user.amount = user.amount.add(delta);
                pool.stakedAmount = pool.stakedAmount.add(delta);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "BITBOOK_STAKING: withdraw not good");
        updatePool(_pid);
        payOrLockupPendingToken(_pid);
        uint256 amountToTransfer = _amount;
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            uint256 _withdrawFee = getWithdrawFee(_pid, user.depositTimestamp);
            uint256 feeAmount = _amount.mul(_withdrawFee).div(1000);
            amountToTransfer = _amount.sub(feeAmount);
            pool.stakedAmount = pool.stakedAmount.sub(_amount);
            pool.stakedToken.safeTransfer(owner(), feeAmount);
            pool.stakedToken.safeTransfer(address(msg.sender), amountToTransfer);
        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, amountToTransfer);
    }

    function payOrLockupPendingToken(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.nextHarvestUntil == 0) {
            user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
        }

        uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(user.rewardDebt);
        if (canHarvest(_pid, msg.sender)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending.add(user.rewardLockedUp);

                user.rewardLockedUp = 0;
                user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);

                rewardReserve.safeTransfer(pool.rewardToken, msg.sender, totalRewards);
                rewardDistributions[_pid] = rewardDistributions[_pid].add(totalRewards);
            }
        } else if (pending > 0) {
            user.rewardLockedUp = user.rewardLockedUp.add(pending);
            emit RewardLockedUp(msg.sender, _pid, pending);
        }
    }

    function getWithdrawFee(uint256 poolId, uint256 stakedTime) public view returns (uint256) {
        uint256 depositTime = block.timestamp.sub(stakedTime);
        WithdrawFeeInterval[] storage _withdrawFee = withdrawFee[poolId];
        uint256 length = _withdrawFee.length;
        for (uint256 i = 0; i < length; i++) {
            if (depositTime <= _withdrawFee[i].day) return _withdrawFee[i].fee;
        }
        return 0;
    }

    function emergencyWithdraw(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        require(amount != 0, "BITBOOK_STAKING: Not enought staked tokens!");
        pool.stakedToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
        delete userInfo[_pid][msg.sender];
    }

    function emergencyAdminWithdraw(uint256 _pid) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 balanceToWithdraw = pool.rewardToken.balanceOf(address(this));
        require(balanceToWithdraw != 0, "BITBOOK_STAKING: Not enough balance to withdraw!");
        pool.rewardToken.transfer(owner(), balanceToWithdraw);
        rewardReserve.safeTransfer(pool.rewardToken, owner(), pool.rewardToken.balanceOf(address(rewardReserve)));
        emit AdminEmergencyWithdraw(_pid, pool.rewardToken.balanceOf(address(this)), pool.accTokenPerShare, pool.tokenPerBlock, pool.lastRewardBlock);
        delete poolInfo[_pid];
    }

    function updatePaused(bool _value) external onlyOwner {
        paused = _value;
        emit PoolPausedUpdated(_value);
    }

    function setLockDeposit(uint256 pid, bool locked) external onlyOwner {
        poolInfo[pid].lockDeposit = locked;
        emit DepositLocked(pid, locked);
    }
}