





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



pragma solidity >=0.6.4;

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

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
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




pragma solidity >=0.6.0 <0.8.0;





library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    
    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        
        
        
        
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
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





pragma solidity >=0.6.0 <0.8.0;




pragma solidity >=0.4.0;






contract FixedBEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _totalMinted;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    
    constructor(string memory name, string memory symbol, uint256 totalSupply) public {
        _name = name;
        _symbol = symbol;
        _totalSupply = totalSupply;
        _decimals = 18;
    }

    
    function getOwner() external override view returns (address) {
        return owner();
    }

    
    function name() public override view returns (string memory) {
        return _name;
    }

    
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    
    function transferFrom (address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'FixedBEP20: transfer amount exceeds allowance')
        );
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, 'FixedBEP20: decreased allowance below zero'));
        return true;
    }

    
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    
    function _transfer (address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), 'FixedBEP20: transfer from the zero address');
        require(recipient != address(0), 'FixedBEP20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'FixedBEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'MELODY: mint to the zero address');
        
        uint256 remainingAmount = _totalSupply.sub(_totalMinted);
        require(remainingAmount != 0, 'MELODY: mint zero amount');

        uint256 mintAmount = amount;
        if (remainingAmount >= amount) {
            mintAmount = amount;
        } else {
            mintAmount = remainingAmount;
        }

        _totalMinted = _totalMinted.add(mintAmount);
        _balances[account] = _balances[account].add(mintAmount);
        emit Transfer(address(0), account, mintAmount);
    }

    
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'FixedBEP20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'FixedBEP20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    
    function _approve (address owner, address spender, uint256 amount) internal {
        require(owner != address(0), 'FixedBEP20: approve from the zero address');
        require(spender != address(0), 'FixedBEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, 'FixedBEP20: burn amount exceeds allowance'));
    }
}



pragma solidity 0.6.12;



contract MelodyToken is FixedBEP20('Melody Token', 'MELODY', 47000000e18) {
    
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    
    
    
    
    

    
    mapping (address => address) internal _delegates;

    
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    
    mapping (address => uint32) public numCheckpoints;

    
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    
    mapping (address => uint) public nonces;

      
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

   
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "MELODY::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "MELODY::delegateBySig: invalid nonce");
        require(now <= expiry, "MELODY::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "MELODY::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; 
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); 
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "MELODY::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}




pragma solidity 0.6.12;














contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    
    struct UserInfo {
        uint256 amount;         
        uint256 rewardDebt;     
        
        
        
        
        
        
        
        
        
        
        
    }

    
    struct PoolInfo {
        IBEP20 lpToken;           
        uint256 allocPoint;       
        uint256 lastRewardBlock;  
        uint256 accMelodyPerShare;   
        uint16 depositFeeBP;      
    }

    
    struct BlockRewardInfo {
        uint256 firstBlock;           
        uint256 lastBlock;            
        uint256 reward;               
    }

    
    MelodyToken public melody;
    
    address public devaddr;
    
    uint256 public constant BONUS_MULTIPLIER = 1;
    
    address public feeAddress;

    
    PoolInfo[] public poolInfo;
    BlockRewardInfo[] public rewardInfo;
    
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    
    uint256 public totalAllocPoint = 0;
    
    uint256 public startBlock;
    
    uint256 public endBlock;

    
    uint256 public blockCountPerDay = 28800;
    
    uint256 public blockCountPerWeek = 201600;
    uint256 private blockRewardUnit = 1e18;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 goosePerBlock);

    constructor(
        MelodyToken _melody,
        address _devaddr,
        address _feeAddress,
        uint256 _startBlock,
        uint256 _endBlock
    ) public { 
        melody = _melody;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        startBlock = _startBlock;
        endBlock = _endBlock;

        setRewardTable(startBlock, endBlock);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(IBEP20 => bool) public poolExistence;
    modifier nonDuplicated(IBEP20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner nonDuplicated(_lpToken) {
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
        lpToken : _lpToken,
        allocPoint : _allocPoint,
        lastRewardBlock : lastRewardBlock,
        accMelodyPerShare : 0,
        depositFeeBP : _depositFeeBP
        }));
    }

    
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    
    function getBlockReward(uint256 _prevBlock, uint256 _currentBlock) public view returns (uint256) {

        uint256 rewardAmount = 0;
        uint256 prevBlock = _prevBlock;
        uint256 currentBlock = _currentBlock;

        if (prevBlock < rewardInfo[0].firstBlock) {
            prevBlock = rewardInfo[0].firstBlock;
        } 

        if (currentBlock > rewardInfo[rewardInfo.length - 1].lastBlock) {
            currentBlock = rewardInfo[rewardInfo.length - 1].lastBlock;
        }

        for (uint256 i = 0; i < rewardInfo.length; i++) {
            BlockRewardInfo memory blockRewardInfo = rewardInfo[i];
            
            if (blockRewardInfo.lastBlock <= prevBlock || blockRewardInfo.firstBlock >= currentBlock) continue;

            if (blockRewardInfo.lastBlock >= currentBlock) {
                uint256 diffBlockCount = currentBlock.sub(prevBlock);
                rewardAmount = rewardAmount.add(diffBlockCount.mul(blockRewardInfo.reward));
                break;
            } else {
                uint256 diffBlockCount = blockRewardInfo.lastBlock.sub(prevBlock);
                rewardAmount = rewardAmount.add(diffBlockCount.mul(blockRewardInfo.reward));
                prevBlock = blockRewardInfo.lastBlock;
            }
        }

        return rewardAmount;
    }

    
    function pendingMelody(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accMelodyPerShare = pool.accMelodyPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 poolReward =  getBlockReward(pool.lastRewardBlock, block.number);
            uint256 melodyReward = poolReward.mul(pool.allocPoint).div(totalAllocPoint);
            accMelodyPerShare = accMelodyPerShare.add(melodyReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accMelodyPerShare).div(1e12).sub(user.rewardDebt);
    }

    
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 poolReward = getBlockReward(pool.lastRewardBlock, block.number);
        uint256 melodyReward =  poolReward.mul(pool.allocPoint).div(totalAllocPoint);
        uint256 treasuryReward = melodyReward.mul(8).div(100);
        uint256 contractReward = melodyReward.mul(92).div(100);
        melody.mint(devaddr, treasuryReward);
        melody.mint(address(this), contractReward);
        pool.accMelodyPerShare = pool.accMelodyPerShare.add(melodyReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accMelodyPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeMelodyTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accMelodyPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accMelodyPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeMelodyTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accMelodyPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    
    function safeMelodyTransfer(address _to, uint256 _amount) internal {
        uint256 melodyBal = melody.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > melodyBal) {
            transferSuccess = melody.transfer(_to, melodyBal);
        } else {
            transferSuccess = melody.transfer(_to, _amount);
        }
        require(transferSuccess, "safeMelodyTransfer: transfer failed");
    }

    
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
        emit SetDevAddress(msg.sender, _devaddr);
    }

    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    function setRewardTable(uint256 _startBlock, uint256 _endBlock) private {

        require(_endBlock > _startBlock, "setRewardTable: Incorrect startBlock and endBlock");

        if (rewardInfo.length > 0) {
            delete rewardInfo;
        }

        uint256 prevBlock = _startBlock;
        uint256 nextBlock = _startBlock.add(blockCountPerDay.mul(4));
        uint256 rewardAmount = 20e18;

        
        rewardInfo.push(BlockRewardInfo({
            firstBlock : prevBlock,
            lastBlock : nextBlock,
            reward : rewardAmount
        }));

        prevBlock = nextBlock;
        
        
        for (uint256 i = 0; i < 10; i++) {
            rewardInfo.push(BlockRewardInfo({
                firstBlock : prevBlock.add(blockCountPerDay.mul(i)),
                lastBlock : prevBlock.add(blockCountPerDay.mul(i + 1)),
                reward : rewardAmount.sub(blockRewardUnit.mul(i + 1))
            }));
        }

        
        prevBlock = prevBlock.add(blockCountPerDay.mul(10));
        nextBlock = prevBlock.add(blockCountPerDay.mul(4));
        rewardAmount = 10e18;
        
        rewardInfo.push(BlockRewardInfo({
            firstBlock : prevBlock,
            lastBlock : nextBlock,
            reward : rewardAmount
        }));
        prevBlock = nextBlock;
        
        for (uint256 i = 0; i < 10; i++) {
            rewardInfo.push(BlockRewardInfo({
                firstBlock : prevBlock.add(blockCountPerDay.mul(i)),
                lastBlock : prevBlock.add(blockCountPerDay.mul(i + 1)),
                reward: rewardAmount.sub(blockRewardUnit.mul(i + 1).div(2))
            }));
        }

        
        prevBlock = prevBlock.add(blockCountPerDay.mul(10));
        nextBlock = prevBlock.add(blockCountPerDay.mul(2));
        rewardAmount = 5e18;
        rewardInfo.push(BlockRewardInfo({
            firstBlock : prevBlock,
            lastBlock : nextBlock,
            reward : rewardAmount
        }));

        prevBlock = nextBlock;
        
        for (uint256 i = 0; i < 5; i++) {
            rewardInfo.push(BlockRewardInfo({
                firstBlock : prevBlock.add(blockCountPerDay.mul(i)),
                lastBlock : prevBlock.add(blockCountPerDay.mul(i + 1)),
                reward: rewardAmount.sub(blockRewardUnit.mul(i + 1).div(2))
            }));
        }

        
        prevBlock = prevBlock.add(blockCountPerDay.mul(5));
        nextBlock = prevBlock.add(blockCountPerDay.mul(7));
        rewardAmount = 25e17;

        rewardInfo.push(BlockRewardInfo({
            firstBlock : prevBlock,
            lastBlock : nextBlock,
            reward : rewardAmount
        }));

        
        prevBlock = nextBlock;
        rewardAmount = 1e18;

        require(_endBlock > prevBlock, "setRewardTable, incorrect end block");
        rewardInfo.push(BlockRewardInfo({
            firstBlock : prevBlock,
            lastBlock : _endBlock,
            reward : rewardAmount
        }));
    }

    function updateStartBlock(uint256 _startBlock) external onlyOwner {
        startBlock = _startBlock;
        setRewardTable(startBlock, endBlock);
    }

    function updateEndBlock(uint256 _endBlock) external onlyOwner {
        endBlock = _endBlock;
        setRewardTable(startBlock, endBlock);
    }

    function rewardPerBlock(uint256 blockNumber) public view returns (uint256) {

        uint256 reward = 0;
        for (uint256 i = 0; i < rewardInfo.length; i++) {
            BlockRewardInfo memory info = rewardInfo[i];
            if (blockNumber >= info.firstBlock && blockNumber < info.lastBlock) {
                reward = info.reward;
                break;
            }
        }
        return reward;
    }
}