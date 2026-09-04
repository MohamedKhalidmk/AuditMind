pragma solidity 0.5.17;

contract Context {
    
    
    constructor () internal { }
    

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
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


contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}


contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    
    function name() public view returns (string memory) {
        return _name;
    }

    
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}


library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}


contract ERC20Mintable is ERC20, MinterRole {
    
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}


contract ERC20Capped is ERC20Mintable {
    uint256 private _cap;

    
    constructor (uint256 cap) public {
        require(cap > 0, "ERC20Capped: cap is 0");
        _cap = cap;
    }

    
    function cap() public view returns (uint256) {
        return _cap;
    }

    
    function _mint(address account, uint256 value) internal {
        require(totalSupply().add(value) <= _cap, "ERC20Capped: cap exceeded");
        super._mint(account, value);
    }
}

contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}


contract Pausable is Context, PauserRole {
    
    event Paused(address account);

    
    event Unpaused(address account);

    bool private _paused;

    
    constructor () internal {
        _paused = false;
    }

    
    function paused() public view returns (bool) {
        return _paused;
    }

    
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


contract ERC20Pausable is ERC20, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}


contract ERC20Burnable is Context, ERC20 {
    
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    
    function owner() public view returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract RICEToken is ERC20, ERC20Detailed, ERC20Capped, ERC20Pausable, ERC20Burnable, Ownable {

    address FoundingTeam = 0x12B8665E7b4684178a54122e121B83CC41d9d9C3;
    address UserAcquisition = 0xdf7E62218B2f889a35a5510e65f9CD4288CB6D6E;
    address PublicSales = 0x876443e20778Daa70BFd2552e815A674D0aA7BF8;
    address PrivateSales = 0x20b803C1d5C9408Bdc5D76648A6F23EB519CD2bD;

    struct LockTime {
        uint256  releaseDate;
        uint256  amount;
    }

    mapping (address => LockTime[]) public lockList;
    mapping (uint => uint) public FoundingTeamMap;
    mapping (uint => uint) public PrivateSalesMap;

    struct Investor {
        address  wallet;
        uint256  amount;
    }

    mapping (uint => Investor) public investorsList;

    uint8 private _d = 18;
    uint256 private totalTokens = 1000000000 * 10 ** uint256(_d);
    uint256 private initialSupply = 600000000 * 10 ** uint256(_d);

    address [] private lockedAddressList;

    constructor() public ERC20Detailed("RICE", "RICE", _d) ERC20Capped(totalTokens) {
        _mint(owner(), initialSupply);

        FoundingTeamMap[1]=1658275200; 
        FoundingTeamMap[2]=1689811200; 
        FoundingTeamMap[3]=1721433600; 
        FoundingTeamMap[4]=1752969600; 
        FoundingTeamMap[5]=1784505600; 

        PrivateSalesMap[1]=1634688000; 
        PrivateSalesMap[2]=1642636800; 
        PrivateSalesMap[3]=1650412800; 
        PrivateSalesMap[4]=1658275200; 
        PrivateSalesMap[5]=1666224000; 
        PrivateSalesMap[6]=1674172800; 
        PrivateSalesMap[7]=1681948800; 
        PrivateSalesMap[8]=1689811200; 
        PrivateSalesMap[9]=1697760000; 
        PrivateSalesMap[10]=1705708800; 

        for(uint i = 1; i <= 5; i++) {
            transferWithLock(FoundingTeam, 30000000 * 10 ** uint256(decimals()), FoundingTeamMap[i]);
        }

        investorsList[1] = Investor({wallet: 0xaDd68b582C54004aaa7eEefA849e47671023Fb9c, amount: 25000000});
        investorsList[2] = Investor({wallet: 0x05f56BA72F05787AD57b6A5b803f2b92b9faa294, amount: 2500000});
        investorsList[3] = Investor({wallet: 0xaC13b80e2880A5e0A4630039273FEefc91315638, amount: 3500000});
        investorsList[4] = Investor({wallet: 0xDe4F4Fd9AE375196cDC22b891Dd13f019d5dd64C, amount: 2500000});
        investorsList[5] = Investor({wallet: 0x0794c84AF1280D25D3CbED6256E11B33F426d59f, amount: 500000});
        investorsList[6] = Investor({wallet: 0x788152f1b4610B74686C5E774e57B9E0986E958c, amount: 1000000});
        investorsList[7] = Investor({wallet: 0x68dCfB21d343b7bD85599a30aAE2521788E09eB7, amount: 5000000});
        investorsList[8] = Investor({wallet: 0xcbf155A2Ec6C35F5af1C2a1dF1bC3BB49980645B, amount: 15000000});
        investorsList[9] = Investor({wallet: 0x7B9f1e95e08A09680c3DB9Fe95b7faEC574a8bBD, amount: 12500000});
        investorsList[10] = Investor({wallet: 0x20b803C1d5C9408Bdc5D76648A6F23EB519CD2bD, amount: 100000000});
        investorsList[11] = Investor({wallet: 0xf6e6715E0B075178c39D07386bE1bf55BAFd9180, amount: 57500000});
        investorsList[12] = Investor({wallet: 0xaCCa1EF5efA7D2C5e8AcAC07F35cD939C1b0C960, amount: 15000000});

        transfer(UserAcquisition, 200000000 * 10 ** uint256(decimals()));
        transfer(PublicSales, 10000000 * 10 ** uint256(decimals()));

    }

    function transfer(address _receiver, uint256 _amount) public returns (bool success) {
        require(_receiver != address(0));
        require(_amount <= getAvailableBalance(msg.sender));
        return ERC20.transfer(_receiver, _amount);
    }

    function transferFrom(address _from, address _receiver, uint256 _amount) public returns (bool) {
        require(_from != address(0));
        require(_receiver != address(0));
        require(_amount <= allowance(_from, msg.sender));
        require(_amount <= getAvailableBalance(_from));
        return ERC20.transferFrom(_from, _receiver, _amount);
    }


    function transferWithLock(address _receiver, uint256 _amount, uint256 _releaseDate) public returns (bool success) {
        require(msg.sender == FoundingTeam || msg.sender == PrivateSales || msg.sender == owner());
        ERC20._transfer(msg.sender,_receiver,_amount);

        if (lockList[_receiver].length==0) lockedAddressList.push(_receiver);

        LockTime memory item = LockTime({amount:_amount, releaseDate:_releaseDate});
        lockList[_receiver].push(item);

        return true;
    }

    function getLockedAmount(address lockedAddress) public view returns (uint256 _amount) {
        uint256 lockedAmount =0;
        for(uint256 j = 0; j<lockList[lockedAddress].length; j++) {
            if(now < lockList[lockedAddress][j].releaseDate) {
                uint256 temp = lockList[lockedAddress][j].amount;
                lockedAmount += temp;
            }
        }
        return lockedAmount;
    }

    function getAvailableBalance(address lockedAddress) public view returns (uint256 _amount) {
        uint256 bal = balanceOf(lockedAddress);
        uint256 locked = getLockedAmount(lockedAddress);
        return bal.sub(locked);
    }

    function getLockedAddresses() public view returns (address[] memory) {
        return lockedAddressList;
    }

    function getNumberOfLockedAddresses() public view returns (uint256 _count) {
        return lockedAddressList.length;
    }

    function getNumberOfLockedAddressesCurrently() public view returns (uint256 _count) {
        uint256 count=0;
        for(uint256 i = 0; i<lockedAddressList.length; i++) {
            if (getLockedAmount(lockedAddressList[i])>0) count++;
        }
        return count;
    }

    function getLockedAddressesCurrently() public view returns (address[] memory) {
        address [] memory list = new address[](getNumberOfLockedAddressesCurrently());
        uint256 j = 0;
        for(uint256 i = 0; i<lockedAddressList.length; i++) {
            if (getLockedAmount(lockedAddressList[i])>0) {
                list[j] = lockedAddressList[i];
                j++;
            }
        }

        return list;
    }

    function getLockedAmountTotal() public view returns (uint256 _amount) {
        uint256 sum =0;
        for(uint256 i = 0; i<lockedAddressList.length; i++) {
            uint256 lockedAmount = getLockedAmount(lockedAddressList[i]);
            sum = sum.add(lockedAmount);
        }
        return sum;
    }

    function getCirculatingSupplyTotal() public view returns (uint256 _amount) {
        return totalSupply().sub(getLockedAmountTotal());
    }

    function getBurnedAmountTotal() public view returns (uint256 _amount) {
        return totalTokens.sub(totalSupply());
    }

    function burn(uint256 _amount) public {
        _burn(msg.sender, _amount);
    }

    function lockInvestor(uint256 investorId) public onlyOwner {
        for(uint y = 3; y <= 10; y++) {
            transferWithLock(investorsList[investorId].wallet, (investorsList[investorId].amount / 8) * 10 ** uint256(decimals()), PrivateSalesMap[y]);
        }
    }

    function () payable external {
        revert();
    }

}