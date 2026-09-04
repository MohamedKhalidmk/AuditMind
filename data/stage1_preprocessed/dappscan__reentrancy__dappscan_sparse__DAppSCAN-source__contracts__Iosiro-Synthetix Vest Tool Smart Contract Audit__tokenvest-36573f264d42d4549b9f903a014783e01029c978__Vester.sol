
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";




contract Vester is ERC721Enumerable {

    struct Grant {
        uint128 vestAmount;
        uint128 totalAmount;
        uint128 amountRedeemed;
        uint64 startTimestamp;
        uint64 cliffTimestamp;
        uint32 vestInterval;
    }

    address public owner;
    address public nominatedOwner;
    address public tokenAddress;
    uint public tokenCounter;
    mapping (uint => Grant) public grants;

    constructor(string memory name, string memory symbol, address _owner, address _tokenAddress) ERC721(name, symbol) {
        owner = _owner;
        tokenAddress = _tokenAddress;
    }

    
    function redeem(uint tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "You don't own this grant.");

        uint128 amount = availableForRedemption(tokenId);
        require(amount > 0, "You don't have any tokens currently available for redemption.");

        IERC20 tokenContract = IERC20(tokenAddress);
        require(tokenContract.balanceOf(address(this)) >= amount, "More tokens must be transferred to this contract before you can redeem.");

        grants[tokenId].amountRedeemed += amount;
        tokenContract.transfer(msg.sender, amount);

        emit Redemption(tokenId, msg.sender, amount);
    }
    
    
    
    
    function redeemWithTransfer(uint tokenId, address incomingTokenAddress, uint incomingTokenAmount) external {
        IERC20 incomingTokenContract = IERC20(incomingTokenAddress);
        require(
            incomingTokenContract.transferFrom(msg.sender, address(this), incomingTokenAmount),
            "Incoming tokens failed to transfer."
        );
        redeem(tokenId);
    }

    
    
    
    
    function availableForRedemption(uint tokenId) public view returns (uint128) {
        return amountVested(tokenId) - grants[tokenId].amountRedeemed;
    }

    
    
    
    function amountVested(uint tokenId) public view returns (uint128) {
        
        if(block.timestamp < grants[tokenId].cliffTimestamp){
            return 0;
        }

        
        uint128 amount = ((uint128(block.timestamp) - grants[tokenId].startTimestamp) / grants[tokenId].vestInterval) * grants[tokenId].vestAmount;

        
        if(amount > grants[tokenId].totalAmount){
            return grants[tokenId].totalAmount;
        }

        return amount;
    }

    
    
    
    function withdraw(address withdrawalTokenAddress, uint withdrawalTokenAmount) public onlyOwner {
        IERC20 tokenContract = IERC20(withdrawalTokenAddress);
        tokenContract.transfer(msg.sender, withdrawalTokenAmount);

        emit Withdrawal(msg.sender, withdrawalTokenAddress, withdrawalTokenAmount);
    }

    
    
    
    
    
    
    
    
    
    function updateGrant(uint tokenId, uint64 startTimestamp, uint64 cliffTimestamp, uint128 vestAmount, uint128 totalAmount, uint128 amountRedeemed, uint32 vestInterval) public onlyOwner {
        grants[tokenId].startTimestamp = startTimestamp;
        grants[tokenId].cliffTimestamp = cliffTimestamp;
        grants[tokenId].vestAmount = vestAmount;
        grants[tokenId].totalAmount = totalAmount;
        grants[tokenId].amountRedeemed = amountRedeemed;
        grants[tokenId].vestInterval = vestInterval;

        emit GrantUpdate(tokenId, startTimestamp, cliffTimestamp, vestAmount, totalAmount, amountRedeemed, vestInterval);
    }

    
    
    
    
    
    
    
    
    
    
    function mint(address granteeAddress, uint64 startTimestamp, uint64 cliffTimestamp, uint128 vestAmount, uint128 totalAmount, uint128 amountRedeemed, uint32 vestInterval) external onlyOwner {
        _safeMint(granteeAddress, tokenCounter);
        updateGrant(tokenCounter, startTimestamp, cliffTimestamp, vestAmount, totalAmount, amountRedeemed, vestInterval);
        tokenCounter++;
    }

    
    
    
    function burn(uint tokenId) external onlyOwner {
        _burn(tokenId);
    }

    
    
    function nominateOwner(address nominee) external onlyOwner {
        nominatedOwner = nominee;
        emit OwnerNomination(nominee);
    }

    
    function acceptOwnership() external {
        require(msg.sender == nominatedOwner);
        emit OwnerUpdate(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    event Redemption(uint indexed tokenId, address indexed redeemerAddress, uint128 amount);
    event GrantUpdate(uint indexed tokenId, uint64 startTimestamp, uint64 cliffTimestamp, uint128 vestAmount, uint128 totalAmount, uint128 amountRedeemed, uint32 vestInterval);
    event Withdrawal(address indexed withdrawerAddress, address indexed withdrawalTokenAddress, uint amount);
    event OwnerNomination(address indexed newOwner);
    event OwnerUpdate(address indexed oldOwner, address indexed newOwner);
}
