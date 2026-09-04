

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ReentrancyGuard.sol";

interface IMigratorChef {
    
    
    
    
    
    
    
    
    
    function migrate(IERC20 token) external returns (IERC20);
}








contract PolkaBridgeFarm is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    struct UserInfo {
        uint256 amount; 
        uint256 rewardDebt; 
        
        
        
        
        
        
        
        
        
        
        
    }
    
    struct PoolInfo {
        IERC20 lpToken; 
        uint256 allocPoint; 
        uint256 lastRewardBlock; 
        uint256 accPBRPerShare; 
    }
    
    address public polkaBridge;
    
    uint256 public PBRPerBlock;
    
    uint256 public constant BONUS_MULTIPLIER = 1;
    
    IMigratorChef public migrator;
    
    PoolInfo[] public poolInfo;
    
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    
    uint256 public totalAllocPoint = 0;
    
    uint256 public startBlock;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken, bool withUpdate);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint, bool withUpdate);
    event LogUpdatePool(uint256 indexed pid, uint256 lastRewardBlock, uint256 lpSupply, uint256 accPBRPerShare);
    event LogSetMigrator(IMigratorChef indexed migrator);

    constructor(
        address _polkaBridge,
        uint256 _PBRPerBlock,
        uint256 _startBlock
    ) {
        polkaBridge = _polkaBridge;
        PBRPerBlock = _PBRPerBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    
    
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accPBRPerShare: 0
            })
        );
        emit LogPoolAddition(poolInfo.length - 1, _allocPoint, _lpToken, _withUpdate);
    }

    
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyOwner {
        if(_withUpdate) {
            massUpdatePools();
        } else {
            updatePool(_pid);
        }
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        emit LogSetPool(_pid, _allocPoint, _withUpdate);
    }

    
    function setMigrator(IMigratorChef _migrator) external onlyOwner {
        migrator = _migrator;
        emit LogSetMigrator(_migrator);
    }

    
    function migrate(uint256 _pid) external {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {        
        return _to - _from * BONUS_MULTIPLIER;
    }

    
    function pendingPBR(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accPBRPerShare = pool.accPBRPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 PBRReward = multiplier * PBRPerBlock * pool.allocPoint / totalAllocPoint;
            accPBRPerShare = accPBRPerShare + PBRReward * 1e18 / lpSupply;
        }
        return user.amount * accPBRPerShare / 1e18 - user.rewardDebt;
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
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 PBRReward = multiplier * PBRPerBlock * pool.allocPoint / totalAllocPoint;
        pool.accPBRPerShare = pool.accPBRPerShare + PBRReward * 1e18 / lpSupply;
        pool.lastRewardBlock = block.number;
        emit LogUpdatePool(_pid, pool.lastRewardBlock, lpSupply, pool.accPBRPerShare);
    }

    
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount * pool.accPBRPerShare / 1e18 - user.rewardDebt;
            IERC20(polkaBridge).safeTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount + _amount;
        user.rewardDebt = user.amount * pool.accPBRPerShare / 1e18;
        emit Deposit(msg.sender, _pid, _amount);
    }

    
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount * pool.accPBRPerShare / 1e18 - user.rewardDebt;
        IERC20(polkaBridge).safeTransfer(msg.sender, pending);
        user.amount = user.amount - _amount;
        user.rewardDebt = user.amount * pool.accPBRPerShare / 1e18;
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    
    function emergencyWithdraw(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

}
