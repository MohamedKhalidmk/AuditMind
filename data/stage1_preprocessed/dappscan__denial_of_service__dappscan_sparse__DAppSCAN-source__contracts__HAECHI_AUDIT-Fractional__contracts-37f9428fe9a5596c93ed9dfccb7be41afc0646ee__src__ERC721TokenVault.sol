
pragma solidity ^0.8.0;

import "./Interfaces/IWETH.sol";
import "./OpenZeppelin/math/Math.sol";
import "./OpenZeppelin/token/ERC20/ERC20.sol";
import "./OpenZeppelin/token/ERC721/ERC721.sol";
import "./OpenZeppelin/token/ERC721/ERC721Holder.sol";

import "./Settings.sol";

contract TokenVault is ERC20, ERC721Holder {

    
    
    

    
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    
    
    

    
    address public token;

    
    uint256 public id;

    
    
    

    
    uint256 public auctionEnd;

    
    uint256 public auctionLength;

    
    uint256 public basePrice;

    
    uint256 public reservePrice;

    
    uint256 public livePrice;

    
    address payable public winning;

    
    bool public auctionLive;

    
    
    

    
    address public settings;

    
    address public curator;

    
    uint256 public fee;

    
    uint256 public lastClaimed;

    
    bool public vaultClosed;

    
    mapping(address => uint256) public userPrices;

    
    
    

    
    event PriceUpdate(address user, uint price);

    
    event Start(address buyer, uint price);

    
    event Bid(address buyer, uint price);

    
    event Won(address buyer, uint price);

    
    event Redeem(address redeemer);

    
    event Cash(address owner, uint256 shares);

    constructor(address _settings, address _curator, address _token, uint256 _id, uint256 _supply, uint256 _listPrice, uint256 _fee, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        settings = _settings;
        token = _token;
        id = _id;
        basePrice = _listPrice;
        reservePrice = _listPrice;
        auctionLength = 7 days;
        curator = _curator;
        fee = _fee;
        lastClaimed = block.timestamp;

        _mint(_curator, _supply);
        _updateUserPrice(_curator, _listPrice);
    }

    
    
    

    
    
    function kickCurator(address _curator) external {
        require(msg.sender == Ownable(settings).owner(), "kick:not gov");

        curator = _curator;
    }

    
    
    

    
    
    function updateCurator(address _curator) external {
        require(msg.sender == curator, "update:not curator");

        curator = _curator;
    }

    
    
    function updateBasePrice(uint256 _price) external {
        require(msg.sender == curator, "update:not curator");

        basePrice = _price;
    }

    
    
    function updateAuctionLength(uint256 _length) external {
        require(msg.sender == curator, "update:not curator");
        require(_length >= ISettings(settings).minAuctionLength() && _length <= ISettings(settings).maxAuctionLength(), "update:invalid auction length");

        auctionLength = _length;
    }

    
    
    function updateFee(uint256 _fee) external {
        require(msg.sender == curator, "update:not curator");
        require(_fee <= ISettings(settings).maxCuratorFee(), "update:cannot increase fee this high");

        _claimFees();

        fee = _fee;
    }

    
    function claimFees() external {
        _claimFees();
    }

    
    function _claimFees() internal {
        
        uint256 currentAnnualFee = fee * totalSupply() / 1000; 
        
        uint256 feePerSecond = currentAnnualFee / 31536000;
        
        uint256 sinceLastClaim = block.timestamp - lastClaimed;
        
        uint256 curatorMint = sinceLastClaim * feePerSecond;

        
        address govAddress = ISettings(settings).feeReceiver();
        uint256 govFee = ISettings(settings).governanceFee();
        currentAnnualFee = govFee * totalSupply() / 1000; 
        feePerSecond = currentAnnualFee / 31536000;
        uint256 govMint = sinceLastClaim * feePerSecond;

        lastClaimed = block.timestamp;

        _mint(curator, curatorMint);
        _mint(govAddress, govMint);
    }

    
    
    

    
    
    function updateUserPrice(uint256 _new) external {
        require(!auctionLive, "update:auction live cannot update price");
        uint256 old = userPrices[msg.sender];
        uint256 weight = balanceOf(msg.sender);

        _updateUserPrice(msg.sender, _new);

        reservePrice = reservePrice - (weight * old / totalSupply()) + (weight * _new / totalSupply());
    }

    
    
    
    
    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal virtual override {
        if (_from != address(0) && !auctionLive && !vaultClosed) {
            uint256 fromPrice = userPrices[_from];
            uint256 toPrice = userPrices[_to] == 0 ? reservePrice : userPrices[_to];

            _updateUserPrice(_to, toPrice);

            
            reservePrice = reservePrice - (_amount * fromPrice / totalSupply()) + (_amount * toPrice / totalSupply());

            
            if (reservePrice < basePrice) {
                uint256 basePriceMin = basePrice * ISettings(settings).minReserveFactor() / 1000;
                reservePrice = Math.max(reservePrice, basePriceMin);
            } else if (reservePrice > basePrice) {
                uint256 basePriceMax = basePrice * ISettings(settings).maxReserveFactor() / 1000;
                reservePrice = Math.min(reservePrice, basePriceMax);
            }
        }
    }

    
    
    
    function _updateUserPrice(address _user, uint256 _price) internal {
        userPrices[_user] = _price;

        emit PriceUpdate(_user, _price);
    }

    
    function start() external payable {
        require(!auctionLive && !vaultClosed, "start:no auction starts");
        require(msg.value >= reservePrice, "start:too low bid");
        
        auctionEnd = block.timestamp + auctionLength;
        auctionLive = true;

        livePrice = msg.value;
        winning = payable(msg.sender);

        emit Start(msg.sender, msg.value);
    }

    
    
    function bid() external payable {
        uint256 increase = ISettings(settings).minBidIncrease() + 1000;
        require(msg.value >= livePrice * increase / 1000, "bid:too low bid");
        require(block.timestamp < auctionEnd, "bid:auction ended");

        
        if (auctionEnd - block.timestamp <= 15 minutes) {
            auctionEnd += 15 minutes;
        }

        _sendETHOrWETH(winning, livePrice);

        livePrice = msg.value;
        winning = payable(msg.sender);

        emit Bid(msg.sender, msg.value);
    }

    
    function end() external {
        require(!vaultClosed, "end:vault has already closed");
        require(block.timestamp >= auctionEnd, "end:auction live");

        
        IERC721(token).safeTransferFrom(address(this), winning, id);

        auctionLive = false;
        vaultClosed = true;

        emit Won(winning, reservePrice);
    }

    
    function redeem() external {
        _burn(msg.sender, totalSupply());
        
        IERC721(token).safeTransferFrom(address(this), msg.sender, id);
        vaultClosed = true;

        emit Redeem(msg.sender);
    }

    
    function cash() external {
        require(vaultClosed, "cash:vault not closed yet");
        uint256 bal = balanceOf(msg.sender);
        require(bal > 0, "cash:no tokens to cash out");
        uint256 share = bal * address(this).balance / totalSupply();
        _burn(msg.sender, bal);

        _sendETHOrWETH(payable(msg.sender), share);

        emit Cash(msg.sender, share);
    }

    
    function _sendETHOrWETH(address who, uint256 amount) internal {
        
        (bool success, ) = who.call{ value: amount }("");
        
        if (!success) {
            IWETH(weth).deposit{value: amount}();
            IWETH(weth).transfer(who, IWETH(weth).balanceOf(address(this)));
        }
    }

}