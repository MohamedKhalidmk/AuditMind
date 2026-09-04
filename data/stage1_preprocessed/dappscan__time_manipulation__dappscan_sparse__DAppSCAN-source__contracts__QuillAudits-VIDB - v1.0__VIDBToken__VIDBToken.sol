

pragma solidity ^0.5.0;


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

contract VIDBToken is ERC20Detailed, ERC20, Ownable {
	address investorWallet = 0x278406d5a5198203ECc54B6a4b3612F174A73f69;
    address reserveWallet = 0x72EBac03226b1937094c09ca3c181b52630695d5;
    address foundationWallet = 0xb6f85f280e30c4f2b2739E62Da8166471a170D23;
    address airdropWallet = 0x638551D8B1a5c582beC4cA978A894CA1B830157E;
    address advisorWallet = 0x5b4774C795A35269FBc858f84B2242d86fEF75Ed;

    uint256 private totalTokens;
    
    struct LockTime {
        uint256  releaseDate;
        uint256  amount;
    }

    mapping (address => LockTime[]) public lockList;
    mapping (uint => uint) public reserveMap;
    mapping (uint => uint) public foundationMap;
    mapping (uint => uint) public airdropMap;
    mapping (uint => uint) public advisorMap;

    address [] private lockedAddressList;

    constructor() public ERC20Detailed("VNDC International Digital Banking", "VIDB", 8) {  

    	reserveMap[1]=1623456000; 
		reserveMap[2]=1639267200; 

		foundationMap[1]=1615507200; 
		foundationMap[2]=1623456000; 
		foundationMap[3]=1631404800; 
		foundationMap[4]=1639267200; 
		foundationMap[5]=1647043200; 
		foundationMap[6]=1654992000; 
		foundationMap[7]=1662940800; 
		foundationMap[8]=1670803200; 
		foundationMap[9]=1678579200; 
		foundationMap[10]=1686528000; 
		foundationMap[11]=1694476800; 
		foundationMap[12]=1702339200; 
		foundationMap[13]=1710201600; 
		foundationMap[14]=1718150400; 
		foundationMap[15]=1726099200; 
		foundationMap[16]=1733961600; 

		airdropMap[1]=1615507200; 
		airdropMap[2]=1623456000; 
		airdropMap[3]=1631404800; 
		airdropMap[4]=1639267200; 
		airdropMap[5]=1647043200; 
		airdropMap[6]=1654992000; 

		advisorMap[1]=1639267200; 


        
        totalTokens = 1000000000 * 10 ** uint256(decimals());
        _mint(owner(), totalTokens); 

        ERC20.transfer(investorWallet, 500000000 * 10 ** uint256(decimals()));
        ERC20.transfer(airdropWallet, 10000000 * 10 ** uint256(decimals()));
        ERC20.transfer(advisorWallet, 25000000 * 10 ** uint256(decimals()));

        for(uint i = 1; i<= 2; i++) {
            transferWithLock(reserveWallet, 125000000 * 10 ** uint256(decimals()), reserveMap[i]);
        }

        for(uint i = 1; i<= 16; i++) {
            transferWithLock(foundationWallet, 7812500 * 10 ** uint256(decimals()), foundationMap[i]);
        }

        for(uint i = 1; i<= 5; i++) {
            transferWithLock(airdropWallet, 8333333 * 10 ** uint256(decimals()), foundationMap[i]);
        }
        transferWithLock(airdropWallet, 8333335 * 10 ** uint256(decimals()), foundationMap[6]);
        
        transferWithLock(advisorWallet, 40000000 * 10 ** uint256(decimals()), advisorMap[1]);
        
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
	    require(msg.sender == reserveWallet || msg.sender == foundationWallet || msg.sender == airdropWallet || msg.sender == advisorWallet || msg.sender == owner());
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

    function () payable external {   
        revert();
    }
}