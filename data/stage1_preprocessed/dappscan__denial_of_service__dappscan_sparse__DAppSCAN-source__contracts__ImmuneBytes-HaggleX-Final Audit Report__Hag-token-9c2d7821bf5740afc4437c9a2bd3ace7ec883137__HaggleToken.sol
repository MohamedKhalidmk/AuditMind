

pragma solidity 0.6.12;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}



library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}


contract Owned is Context {

    address public _owner;
    address public _newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(_msgSender() == _owner, "HaggleX Token: Only Owner can perform this task");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _newOwner = newOwner;
    }

    function acceptOwnership() external {
        require(_msgSender() == _newOwner, "HaggleX Token: Token Contract Ownership has not been set for the address");
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
        _newOwner = address(0);
    }
}







contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;


    string private _name;
    string private _symbol;
    uint8 private _decimals;

    bool private _paused;

    mapping(address => bool) private _blacklists;




    
    constructor (string memory name_, string memory symbol_, uint8 decimals_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;


        _paused = false;
    }

    

    
    function name() external view returns (string memory) {
        return _name;
    }



    
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    
    function paused() external view returns (bool) {
        return _paused;
    }

    
    function blacklisted(address _address) external view returns (bool) {
        return _blacklists[_address];
    }



    
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "HaggleX Token: transfer amount exceeds allowance"));
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "HaggleX Token: decreased allowance below zero"));
        return true;
    }


    
     function _pause() internal virtual  {
        require(_paused == false, "HaggleX Token: token transfer is unavailable");
        _paused = true;
    }

    
    function _unpause() internal virtual  {
        require(_paused == true, "HaggleX Token: token transfer is available");
        _paused = false;
    }

    
    function _blacklist(address _address) internal virtual {
        require(_blacklists[_address] == false, "HaggleX Token: account already blacklisted");
        _blacklists[_address] = true;
    }

    
    function _whitelist(address _address) internal virtual {
        require(_blacklists[_address] == true, "HaggleX Token: account already whitelisted");
        _blacklists[_address] = false;
    }

    


    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "HaggleX Token: transfer from the zero address");
        require(recipient != address(0), "HaggleX Token: transfer to the zero address");
        require(_paused == false, "HaggleX Token: token contract is not available");
        require(_blacklists[sender] == false,"HaggleX Token: sender account already blacklisted");
        require(_blacklists[recipient] == false,"HaggleX Token: sender account already blacklisted");


        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "HaggleX Token: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "HaggleX Token: mint to the zero address");
        require(_paused == false, "HaggleX Token: token contract is not available");
        require(_blacklists[account] == false,"HaggleX Token: account to mint to already blacklisted");



        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        require(_paused == false, "HaggleX Token: token contract is not available");
        require(_blacklists[account] == false,"HaggleX Token: account to burn from already blacklisted");



        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "HaggleX Token: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }


    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "HaggleX Token: approve from the zero address");
        require(spender != address(0), "HaggleX Token: approve to the zero address");
        require(_paused == false, "HaggleX Token: token contract approve is not available");
        require(_blacklists[owner] == false,"HaggleX Token: owner account already blacklisted");
        require(_blacklists[spender] == false,"HaggleX Token: spender account already blacklisted");



        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}




contract HaggleXToken is ERC20, Owned {
    using SafeMath for uint;
    
    event staked(address sender, uint amount, uint lockedTime);
    event unstaked(address sender, uint amount);
    
    address private _minter;

    uint private stakedSupply = 0;

    
    uint8 private STAKERS_PERCENTAGE = 60;
    uint8 private LEADERSHIP_BOARD_PERCENTAGE = 20;
    uint8 private UNIVERSAL_BASIC_INCOME_PERCENTAGE = 5;
    uint8 private DEVELOPMENT_PERCENTAGE = 15;

    
    address private CORE_TEAM = 0x821e90F8a572B62604877A2d5aa740Da0abDa07F;
    address private ADVISORS = 0x7610269058d82eC1F2E66a0ff981056622D387F6;
    address private CORE_INVESTORS = 0x811a622EB3e2a1a0Af8aE1a9AAaE8D1DC6016534;
    address private RESERVE = 0x609B1D6C5E6E2B48bfCe70eD7f88bAA3ECB9ca9d;
    address private CHARITY = 0x76a6a41282434a784e88Afc91Bd3E552A6F560f1;
    address private FOUNDING_STAFF = 0xAbE2526c2F8117B081817273d56fa09c4bcBDc49;
    address private AIRGRAB = 0xF985905b1510d51fd3da563D530263481F7c2a18;
    
    address private LEADERSHIP_BOARD = 0x7B9A1CF604396160F543f0FFaE50E076e15f39c8;
    address private UNIVERSAL_BASIC_INCOME = 0x9E7481AeD2585eC09066B8923570C49A38E06eAF;
    address private DEVELOPMENT = 0xaC92741D5BcDA49Ce0FF35a3D5be710bA870B260;
    
    

    struct StakeType {
        uint rewardPercent; 
        uint lockedTime; 
        uint totalStaked; 
    }
    
    mapping(uint => StakeType) private _stakingOptions;
    
    struct Stake {
        uint amount; 
        uint startTime; 
        uint stakeType; 
        uint lastWithdrawTime; 
        uint noOfWithdrawals; 
    }
    mapping(address => Stake[]) private _staking;
    
    constructor () public  ERC20("HaggleX Token", "HAG", 18){
                
       
        
        _stakingOptions[9].rewardPercent = 100;
        _stakingOptions[9].lockedTime = 20 minutes;
        _stakingOptions[9].totalStaked = 0;

        
        _stakingOptions[8].rewardPercent = 50;
        _stakingOptions[8].lockedTime = 30 minutes;
        _stakingOptions[8].totalStaked = 0;


        
        _stakingOptions[0].rewardPercent = 15;
        _stakingOptions[0].lockedTime = 12 weeks;
        _stakingOptions[0].totalStaked = 0;
        
        
        _stakingOptions[1].rewardPercent = 30;
        _stakingOptions[1].lockedTime = 24 weeks;
        _stakingOptions[1].totalStaked = 0;

        
        
        _stakingOptions[2].rewardPercent = 55;
        _stakingOptions[2].lockedTime = 48 weeks;
        _stakingOptions[2].totalStaked = 0;

        
        _owner = _msgSender();
        
        _mint(CORE_TEAM, 100000 ether);
        _mint(ADVISORS, 40000 ether);
        _mint(CORE_INVESTORS, 60000 ether);
        _mint(RESERVE, 100000 ether);
        _mint(CHARITY, 20000 ether);
        _mint(FOUNDING_STAFF, 80000 ether);
        _mint(AIRGRAB, 100000 ether);

    }
    
    
    function getTotalSupply() public view returns(uint) {
        return totalSupply() + stakedSupply;
    }
    
    
    function getMyBalance() external view returns(uint) {
        return balanceOf(_msgSender());
    }

    
    
    function getMyFullBalance() external view returns(uint) {
        uint balance = balanceOf(_msgSender());
        for (uint i = 0; i < _staking[_msgSender()].length; i++){
            balance += getStakeAmount(i);
        } 
        return balance;
    }



      
    function getStakes() external view returns (uint[3][] memory) {
        uint[3][] memory tempStakeList = new uint[3][](_staking[_msgSender()].length);
        for (uint i = 0; i < _staking[_msgSender()].length; i++){
            tempStakeList[i][0] = getStakeAmount(i);
            tempStakeList[i][1] = getRemainingLockTime(i);
            tempStakeList[i][2] = calculateDailyStakeReward(i);
        } 
        return tempStakeList;
    }
    
    

    
    
    function setMinter(address minter_) external onlyOwner {
        _minter = minter_;
    }

    
    function pause() external onlyOwner  {
        _pause();
    }
    
    
    function unpause() external onlyOwner {
        _unpause();
    }

      
    function blacklist(address _address) external onlyOwner {
        _blacklist(_address);
    }    

    
    function whitelist(address _address) external onlyOwner {
        _whitelist(_address);
    } 

     
    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }
    
    
    function burnFrom(address account, uint256 amount) external {
         uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "HaggleX Token: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }


    
    function mint(address address_, uint256 amount_) external {
        require(_msgSender() == _minter || _msgSender() == _owner, "HaggleX Token: Only minter and owner can mint tokens!");
        _mint(address_, amount_);
    }
    
    
    function mintToMultipleAddresses(address[] memory _addresses, uint _amount) external onlyOwner {
        for(uint i = 0; i < _addresses.length; i++){
            _mint(_addresses[i],  _amount);
        }
    }
    
    
  
   
    
    function isStakeLocked(uint stake_) private view returns (bool) {
        uint stakingTime = block.timestamp - _staking[_msgSender()][stake_].startTime;
        return stakingTime < _stakingOptions[_staking[_msgSender()][stake_].stakeType].lockedTime;
    }
    
    
    function getRemainingLockTime(uint stake_) public view returns (uint) {
        uint stakingTime = block.timestamp - _staking[_msgSender()][stake_].startTime;
        if (stakingTime < _stakingOptions[_staking[_msgSender()][stake_].stakeType].lockedTime) {
            return _stakingOptions[_staking[_msgSender()][stake_].stakeType].lockedTime - stakingTime;
        } else {
            return 0;
        }
    }
    
    
    function getLastWithdrawalTime(uint stake_) external view returns (uint) {
       return _staking[_msgSender()][stake_].lastWithdrawTime;
    }
    
    
    function getNoOfWithdrawals(uint stake_) external view returns (uint) {
        return _staking[_msgSender()][stake_].noOfWithdrawals;
    }
    
    
      
    function getStakeAmount(uint stake_) public view returns (uint) {
        return _staking[_msgSender()][stake_].amount;
    } 


    
    function getTotalStakedAmount(uint stakeType_) public view returns (uint) {
        return _stakingOptions[stakeType_].totalStaked;
    }



    
    
    
    function getStakePercentageReward(uint stakeType_) private view returns (uint) {
        uint rewardPerc = getHalvedReward().mul(STAKERS_PERCENTAGE).mul(_stakingOptions[stakeType_].rewardPercent);
        return  rewardPerc.div(10000);
    }
    
    function getLeadershipBoardPercentageReward() private view returns (uint) {
        uint rewardPerc = getHalvedReward().mul(LEADERSHIP_BOARD_PERCENTAGE);
        return  rewardPerc.div(100);
    }
    
    function getUBIPercentageReward() private view returns (uint) {
        uint rewardPerc = getHalvedReward().mul(UNIVERSAL_BASIC_INCOME_PERCENTAGE);
        return  rewardPerc.div(100);
    }
    
    function getDevelopmentPercentageReward() private view returns (uint) {
        uint rewardPerc = getHalvedReward().mul(DEVELOPMENT_PERCENTAGE);
        return  rewardPerc.div(100);
    }
    


    
    function getHalvedReward() public view returns (uint) {
            
            uint reward;

            if (getTotalSupply() >= 1000000 ether && getTotalSupply() <= 1116800 ether) {
               reward =  80 ether;
            }
            else if (getTotalSupply() > 1116800 ether && getTotalSupply() <= 1175200 ether) {
               
               reward =  40 ether;
            }
            else if (getTotalSupply() > 1175200 ether && getTotalSupply() <= 1204400 ether) { 
               
               reward =  20 ether;
            }
            else if (getTotalSupply() > 1204400 ether && getTotalSupply() <= 1219000 ether) { 
               
               reward =  10 ether;
            }
            else if (getTotalSupply() > 1219000 ether && getTotalSupply() <= 1226300 ether) { 
               
               reward =  5 ether;
            }
            else if (getTotalSupply() > 1226300 ether && getTotalSupply() <= 1229950 ether) { 
               
               reward =  2.5 ether;
            }
            else if (getTotalSupply() > 1229950 ether && getTotalSupply() <= 1231775 ether) { 
               
               reward =  1.25 ether;
            }
            else if (getTotalSupply() > 1231775 ether) { 
               
               reward =  0.625 ether;
            }
            else {

               reward =  0 ether;
            }
            
            return reward;
        }

    
    
    
    
     
    function calculateDailyStakeReward(uint stake_) public view returns (uint) {
        uint reward = getStakeAmount(stake_).mul(getStakePercentageReward(_staking[_msgSender()][stake_].stakeType));
        return reward.div(getTotalStakedAmount(_staking[_msgSender()][stake_].stakeType));
    }
    
    
            
    
    function withdrawStakeReward(uint stake_) external {
        require(isStakeLocked(stake_) == true, "Withdrawal no longer available, you can only Unstake now!");
        require(block.timestamp >= _staking[_msgSender()][stake_].lastWithdrawTime + 10 minutes, "Not yet time to withdraw reward");
        _staking[_msgSender()][stake_].noOfWithdrawals++;
        _staking[_msgSender()][stake_].lastWithdrawTime = block.timestamp;
        uint _amount = calculateDailyStakeReward(stake_);
        _mint(_msgSender(), _amount);    
    }
    
    function withdrawLeadershipBoardReward() external onlyOwner {
        uint lastWithdrawTime = 1614556800;
        require(block.timestamp >= lastWithdrawTime + 10 minutes, "Not yet time to withdraw Leadership Board reward");
        lastWithdrawTime = block.timestamp;
        uint _amount = getLeadershipBoardPercentageReward();
        _mint(LEADERSHIP_BOARD, _amount);    
    }
    
    function withdrawUBIReward() external onlyOwner {
        uint lastWithdrawTime = 1614556800;
        require(block.timestamp >= lastWithdrawTime + 10 minutes, "Not yet time to withdraw Leadership Board reward");
        lastWithdrawTime = block.timestamp;
        uint _amount = getUBIPercentageReward();
        _mint(UNIVERSAL_BASIC_INCOME, _amount);    
    }
    
    function withdrawDevelopmentReward() external onlyOwner {
        uint lastWithdrawTime = 1614556800;
        require(block.timestamp >= lastWithdrawTime + 10 minutes, "Not yet time to withdraw Leadership Board reward");
        lastWithdrawTime = block.timestamp;
        uint _amount = getDevelopmentPercentageReward();
        _mint(DEVELOPMENT, _amount);    
    }

    
     
    function stake(uint amount_, uint stakeType_) external {
        _burn(_msgSender(), amount_);
        stakedSupply += amount_;
        Stake memory temp;
        temp.amount = amount_;
        temp.startTime = block.timestamp;
        temp.stakeType = stakeType_;    
        temp.lastWithdrawTime = block.timestamp;
        temp.noOfWithdrawals = 0;
        
        _staking[_msgSender()].push(temp);
        _stakingOptions[stakeType_].totalStaked += amount_;
        emit staked(_msgSender(), amount_, _stakingOptions[stakeType_].lockedTime);
    }
    
    
    
    
    function unstake(uint stake_) external {
        require(isStakeLocked(stake_) != true, "HaggleX Token:Stake still locked!");
        uint _amount = _staking[_msgSender()][stake_].amount;
        _mint(_msgSender(), _amount);
        stakedSupply -= _amount;
        _stakingOptions[stake_].totalStaked -= _amount;
        _removeIndexInArray(_staking[_msgSender()], stake_);
        emit unstaked(_msgSender(), _amount);
    }
    
    
    
    
    function _removeIndexInArray(Stake[] storage _array, uint _index) private {
        if (_index >= _array.length) return;
        for (uint i = _index; i<_array.length-1; i++){
            _array[i] = _array[i+1];
        }
        _array.pop();
    }
    
}
