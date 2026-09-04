pragma solidity ^0.5.16;

import "./CToken.sol";

interface IFlashloanReceiver {
    function executeOperation(address sender, address underlying, uint amount, uint fee, bytes calldata params) external;
}


contract CCapableErc20 is CToken, CCapableErc20Interface, CCapableDelegateInterface {

    event Flashloan(address indexed receiver, uint amount, uint totalFee, uint reservesFee);
    uint constant flashFeeBips = 3;

    
    function initialize(address underlying_,
                        ComptrollerInterface comptroller_,
                        InterestRateModel interestRateModel_,
                        uint initialExchangeRateMantissa_,
                        string memory name_,
                        string memory symbol_,
                        uint8 decimals_) public {
        
        super.initialize(comptroller_, interestRateModel_, initialExchangeRateMantissa_, name_, symbol_, decimals_);

        
        underlying = underlying_;
        EIP20Interface(underlying).totalSupply();
    }

    

    
    function mint(uint mintAmount) external returns (uint) {
        (uint err,) = mintInternal(mintAmount);
        return err;
    }

    
    function redeem(uint redeemTokens) external returns (uint) {
        return redeemInternal(redeemTokens);
    }

    
    function redeemUnderlying(uint redeemAmount) external returns (uint) {
        return redeemUnderlyingInternal(redeemAmount);
    }

    
    function borrow(uint borrowAmount) external returns (uint) {
        return borrowInternal(borrowAmount);
    }

    
    function repayBorrow(uint repayAmount) external returns (uint) {
        (uint err,) = repayBorrowInternal(repayAmount);
        return err;
    }

    
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint) {
        (uint err,) = repayBorrowBehalfInternal(borrower, repayAmount);
        return err;
    }

    
    function liquidateBorrow(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) external returns (uint) {
        (uint err,) = liquidateBorrowInternal(borrower, repayAmount, cTokenCollateral);
        return err;
    }

    
    function _addReserves(uint addAmount) external returns (uint) {
        return _addReservesInternal(addAmount);
    }

    
    
    function gulp() external {
        uint256 cashOnChain = getCashOnChain();
        uint256 cashPrior = getCashPrior();

        uint excessCash = sub_(cashOnChain, cashPrior);
        totalReserves = add_(totalReserves, excessCash);
        internalCash = cashOnChain;
    }

    

    
    function getCashPrior() internal view returns (uint) {
        return internalCash;
    }

    
    function getCashOnChain() internal view returns (uint) {
        EIP20Interface token = EIP20Interface(underlying);
        return token.balanceOf(address(this));
    }

    
    function doTransferIn(address from, uint amount) internal returns (uint) {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(underlying);
        uint balanceBefore = EIP20Interface(underlying).balanceOf(address(this));
        token.transferFrom(from, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {                       
                    success := not(0)          
                }
                case 32 {                      
                    returndatacopy(0, 0, 32)
                    success := mload(0)        
                }
                default {                      
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        
        uint balanceAfter = EIP20Interface(underlying).balanceOf(address(this));
        uint transferredIn = sub_(balanceAfter, balanceBefore);
        internalCash = add_(internalCash, transferredIn);
        return transferredIn;
    }

    
    function doTransferOut(address payable to, uint amount) internal {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(underlying);
        token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {                      
                    success := not(0)          
                }
                case 32 {                     
                    returndatacopy(0, 0, 32)
                    success := mload(0)        
                }
                default {                     
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
        internalCash = sub_(internalCash, amount);
    }

    function flashLoan(address receiver, uint amount, bytes calldata params) external nonReentrant {
        uint cashOnChainBefore = getCashOnChain();
        uint cashBefore = getCashPrior();
        require(cashBefore >= amount, "INSUFFICIENT_LIQUIDITY");

        
        uint totalFee = div_(mul_(amount, flashFeeBips), 10000);

        
        doTransferOut(address(uint160(receiver)), amount);

        
        IFlashloanReceiver(receiver).executeOperation(msg.sender, underlying, amount, totalFee, params);

        
        uint cashOnChainAfter = getCashOnChain();
        require(cashOnChainAfter == add_(cashOnChainBefore, totalFee), "BALANCE_INCONSISTENT");

        
        uint reservesFee = mul_ScalarTruncate(Exp({mantissa: reserveFactorMantissa}), totalFee);
        totalReserves = add_(totalReserves, reservesFee);
        internalCash = add_(cashBefore, totalFee);

        emit Flashloan(receiver, amount, totalFee, reservesFee);
    }
}
