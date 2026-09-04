
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IYearnVaultV2.sol";
import "./WrappedPosition.sol";



contract YVaultAssetProxy is WrappedPosition {
    IYearnVault public immutable vault;
    uint8 public immutable vaultDecimals;

    
    

    
    mapping(address => uint256) public reserveBalances;
    
    
    uint128 public reserveUnderlying;
    uint128 public reserveShares;
    
    uint256 public reserveSupply;

    
    
    
    
    
    
    constructor(
        address vault_,
        IERC20 _token,
        string memory _name,
        string memory _symbol
    ) WrappedPosition(_token, _name, _symbol) {
        vault = IYearnVault(vault_);
        _token.approve(vault_, type(uint256).max);
        vaultDecimals = IERC20(vault_).decimals();
    }

    
    
    
    
    
    
    function reserveDeposit(uint256 _amount) external {
        
        
        token.transferFrom(msg.sender, address(this), _amount);
        
        (uint256 localUnderlying, uint256 localShares) = _getReserves();
        
        uint256 totalValue = localUnderlying;
        totalValue += _underlying(localShares);
        
        uint256 localReserveSupply = reserveSupply;
        uint256 mintAmount;
        if (localReserveSupply == 0) {
            
            mintAmount = _amount;
        } else {
            
            mintAmount = (localReserveSupply * _amount) / totalValue;
        }

        
        
        
        if (localUnderlying == 0 && localShares == 0) {
            _amount -= 1;
        }
        
        _setReserves(localUnderlying + _amount, localShares);
        
        reserveBalances[msg.sender] += mintAmount;
        reserveSupply = localReserveSupply + mintAmount;
    }

    
    
    function reserveWithdraw(uint256 _amount) external {
        
        reserveBalances[msg.sender] -= _amount;
        
        (uint256 localUnderlying, uint256 localShares) = _getReserves();
        uint256 localReserveSupply = reserveSupply;
        
        uint256 userShares = (localShares * _amount) / localReserveSupply;
        
        uint256 freedUnderlying = vault.withdraw(userShares, address(this), 0);
        
        uint256 userUnderlying = (localUnderlying * _amount) /
            localReserveSupply;

        
        _setReserves(
            localUnderlying - userUnderlying,
            localShares - userShares
        );
        
        reserveSupply = localReserveSupply - _amount;

        
        
        token.transfer(msg.sender, freedUnderlying + userUnderlying);
    }

    
    
    
    function _deposit() internal override returns (uint256, uint256) {
        
        (uint256 localUnderlying, uint256 localShares) = _getReserves();
        
        uint256 amount = token.balanceOf(address(this)) - localUnderlying;
        
        if (localUnderlying != 0 || localShares != 0) {
            amount -= 1;
        }
        
        
        
        uint256 yearnTotalSupply = vault.totalSupply();
        uint256 yearnTotalAssets = vault.totalAssets();
        uint256 neededShares = (amount * yearnTotalSupply) / yearnTotalAssets;
        
        if (localShares > neededShares) {
            
            _setReserves(localUnderlying + amount, localShares - neededShares);
            
            return (neededShares, amount);
        }
        
        uint256 shares = vault.deposit(localUnderlying + amount, address(this));
        
        _setReserves(0, shares - neededShares);
        
        return (neededShares, amount);
    }

    
    
    
    
    function _withdraw(
        uint256 _shares,
        address _destination,
        uint256 _underlyingPerShare
    ) internal override returns (uint256) {
        
        if (_underlyingPerShare == 0) {
            _underlyingPerShare = _pricePerShare();
        }
        
        (uint256 localUnderlying, uint256 localShares) = _getReserves();
        
        uint256 needed = (_shares * _underlyingPerShare) / 10**vaultDecimals;
        if (needed < localUnderlying) {
            
            _setReserves(localUnderlying - needed, localShares + _shares);
            
            
            token.transfer(_destination, needed);
            
            return (needed);
        }
        
        
        uint256 amountReceived = vault.withdraw(
            _shares + localShares,
            address(this),
            1
        );
        _setReserves(amountReceived - needed, 0);
        
        token.transfer(_destination, needed);
        
        return needed;
    }

    
    
    
    function _underlying(uint256 _amount)
        internal
        override
        view
        returns (uint256)
    {
        uint256 yearnTotalSupply = vault.totalSupply();
        uint256 yearnTotalAssets = vault.totalAssets();
        return (yearnTotalAssets * _amount) / yearnTotalSupply;
    }

    
    
    function _pricePerShare() internal view returns (uint256) {
        return vault.pricePerShare();
    }

    
    function approve() external {
        token.approve(address(vault), 0);
        token.approve(address(vault), type(uint256).max);
    }

    
    
    function _getReserves() internal view returns (uint256, uint256) {
        return (uint256(reserveUnderlying), uint256(reserveShares));
    }

    
    
    
    function _setReserves(
        uint256 _newReserveUnderlying,
        uint256 _newReserveShares
    ) internal {
        reserveUnderlying = uint128(_newReserveUnderlying);
        reserveShares = uint128(_newReserveShares);
    }
}
