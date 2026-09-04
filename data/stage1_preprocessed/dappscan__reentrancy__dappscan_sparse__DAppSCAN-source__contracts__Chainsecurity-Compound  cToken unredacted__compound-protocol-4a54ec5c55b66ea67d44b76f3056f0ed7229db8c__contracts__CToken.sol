
pragma solidity ^0.8.6;

import "./ComptrollerInterface.sol";
import "./CTokenInterfaces.sol";
import "./ErrorReporter.sol";
import "./EIP20Interface.sol";
import "./InterestRateModel.sol";
import "./ExponentialNoError.sol";


abstract contract CToken is CTokenInterface, ExponentialNoError, TokenErrorReporter {
    
    function initialize(ComptrollerInterface comptroller_,
                        InterestRateModel interestRateModel_,
                        uint initialExchangeRateMantissa_,
                        string memory name_,
                        string memory symbol_,
                        uint8 decimals_) public {
        require(msg.sender == admin, "only admin may initialize the market");
        require(accrualBlockNumber == 0 && borrowIndex == 0, "market may only be initialized once");

        
        initialExchangeRateMantissa = initialExchangeRateMantissa_;
        require(initialExchangeRateMantissa > 0, "initial exchange rate must be greater than zero.");

        
        uint err = _setComptroller(comptroller_);
        require(err == NO_ERROR, "setting comptroller failed");

        
        accrualBlockNumber = getBlockNumber();
        borrowIndex = mantissaOne;

        
        err = _setInterestRateModelFresh(interestRateModel_);
        require(err == NO_ERROR, "setting interest rate model failed");

        name = name_;
        symbol = symbol_;
        decimals = decimals_;

        
        _notEntered = true;
    }

    
    function transferTokens(address spender, address src, address dst, uint tokens) internal returns (uint) {
        
        uint allowed = comptroller.transferAllowed(address(this), src, dst, tokens);
        if (allowed != 0) {
            revert TransferComptrollerRejection(allowed);
        }

        
        if (src == dst) {
            revert TransferNotAllowed();
        }

        
        uint startingAllowance = 0;
        if (spender == src) {
            startingAllowance = type(uint).max;
        } else {
            startingAllowance = transferAllowances[src][spender];
        }

        
        uint allowanceNew = startingAllowance - tokens;
        uint srcTokensNew = accountTokens[src] - tokens;
        uint dstTokensNew = accountTokens[dst] + tokens;

        
        
        

        accountTokens[src] = srcTokensNew;
        accountTokens[dst] = dstTokensNew;

        
        if (startingAllowance != type(uint).max) {
            transferAllowances[src][spender] = allowanceNew;
        }

        
        emit Transfer(src, dst, tokens);

        
        

        return NO_ERROR;
    }

    
    function transfer(address dst, uint256 amount) override external nonReentrant returns (bool) {
        return transferTokens(msg.sender, msg.sender, dst, amount) == NO_ERROR;
    }

    
    function transferFrom(address src, address dst, uint256 amount) override external nonReentrant returns (bool) {
        return transferTokens(msg.sender, src, dst, amount) == NO_ERROR;
    }

    
    function approve(address spender, uint256 amount) override external returns (bool) {
        address src = msg.sender;
        transferAllowances[src][spender] = amount;
        emit Approval(src, spender, amount);
        return true;
    }

    
    function allowance(address owner, address spender) override external view returns (uint256) {
        return transferAllowances[owner][spender];
    }

    
    function balanceOf(address owner) override external view returns (uint256) {
        return accountTokens[owner];
    }

    
    function balanceOfUnderlying(address owner) override external returns (uint) {
        Exp memory exchangeRate = Exp({mantissa: exchangeRateCurrent()});
        return mul_ScalarTruncate(exchangeRate, accountTokens[owner]);
    }

    
    function getAccountSnapshot(address account) override external view returns (uint, uint, uint, uint) {
        return (
            NO_ERROR,
            accountTokens[account],
            borrowBalanceStoredInternal(account),
            exchangeRateStoredInternal()
        );
    }

    
    function getBlockNumber() virtual internal view returns (uint) {
        return block.number;
    }

    
    function borrowRatePerBlock() override external view returns (uint) {
        return interestRateModel.getBorrowRate(getCashPrior(), totalBorrows, totalReserves);
    }

    
    function supplyRatePerBlock() override external view returns (uint) {
        return interestRateModel.getSupplyRate(getCashPrior(), totalBorrows, totalReserves, reserveFactorMantissa);
    }

    
    function totalBorrowsCurrent() override external nonReentrant returns (uint) {
        require(accrueInterest() == NO_ERROR, "accrue interest failed");
        return totalBorrows;
    }

    
    function borrowBalanceCurrent(address account) override external nonReentrant returns (uint) {
        require(accrueInterest() == NO_ERROR, "accrue interest failed");
        return borrowBalanceStored(account);
    }

    
    function borrowBalanceStored(address account) override public view returns (uint) {
        return borrowBalanceStoredInternal(account);
    }

    
    function borrowBalanceStoredInternal(address account) internal view returns (uint) {
        
        BorrowSnapshot storage borrowSnapshot = accountBorrows[account];

        
        if (borrowSnapshot.principal == 0) {
            return 0;
        }

        
        uint principalTimesIndex = borrowSnapshot.principal * borrowIndex;
        return principalTimesIndex / borrowSnapshot.interestIndex;
    }

    
    function exchangeRateCurrent() override public nonReentrant returns (uint) {
        require(accrueInterest() == NO_ERROR, "accrue interest failed");
        return exchangeRateStored();
    }

    
    function exchangeRateStored() override public view returns (uint) {
        return exchangeRateStoredInternal();
    }

    
    function exchangeRateStoredInternal() virtual internal view returns (uint) {
        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            
            return initialExchangeRateMantissa;
        } else {
            
            uint totalCash = getCashPrior();
            uint cashPlusBorrowsMinusReserves = totalCash + totalBorrows - totalReserves;
            Exp memory exchangeRate = Exp({mantissa: cashPlusBorrowsMinusReserves * expScale / _totalSupply});

            return exchangeRate.mantissa;
        }
    }

    
    function getCash() override external view returns (uint) {
        return getCashPrior();
    }

    
    function accrueInterest() virtual override public returns (uint) {
        
        uint currentBlockNumber = getBlockNumber();
        uint accrualBlockNumberPrior = accrualBlockNumber;

        
        if (accrualBlockNumberPrior == currentBlockNumber) {
            return NO_ERROR;
        }

        
        uint cashPrior = getCashPrior();
        uint borrowsPrior = totalBorrows;
        uint reservesPrior = totalReserves;
        uint borrowIndexPrior = borrowIndex;

        
        uint borrowRateMantissa = interestRateModel.getBorrowRate(cashPrior, borrowsPrior, reservesPrior);
        require(borrowRateMantissa <= borrowRateMaxMantissa, "borrow rate is absurdly high");

        
        uint blockDelta = currentBlockNumber - accrualBlockNumberPrior;

        

        Exp memory simpleInterestFactor = mul_(Exp({mantissa: borrowRateMantissa}), blockDelta);
        uint interestAccumulated = mul_ScalarTruncate(simpleInterestFactor, borrowsPrior);
        uint totalBorrowsNew = interestAccumulated + borrowsPrior;
        uint totalReservesNew = mul_ScalarTruncateAddUInt(Exp({mantissa: reserveFactorMantissa}), interestAccumulated, reservesPrior);
        uint borrowIndexNew = mul_ScalarTruncateAddUInt(simpleInterestFactor, borrowIndexPrior, borrowIndexPrior);

        
        
        

        
        accrualBlockNumber = currentBlockNumber;
        borrowIndex = borrowIndexNew;
        totalBorrows = totalBorrowsNew;
        totalReserves = totalReservesNew;

        
        emit AccrueInterest(cashPrior, interestAccumulated, borrowIndexNew, totalBorrowsNew);

        return NO_ERROR;
    }

    
    function mintInternal(uint mintAmount) internal nonReentrant {
        uint error = accrueInterest();
        if (error != NO_ERROR) {
            
            revert MintAccrueInterestFailed(error);
        }
        
        mintFresh(msg.sender, mintAmount);
    }

    
    function mintFresh(address minter, uint mintAmount) internal {
        
        uint allowed = comptroller.mintAllowed(address(this), minter, mintAmount);
        if (allowed != 0) {
            revert MintComptrollerRejection(allowed);
        }

        
        if (accrualBlockNumber != getBlockNumber()) {
            revert MintFreshnessCheck();
        }

        Exp memory exchangeRate = Exp({mantissa: exchangeRateStoredInternal()});

        
        
        

        
        uint actualMintAmount = doTransferIn(minter, mintAmount);

        

        uint mintTokens = div_(actualMintAmount, exchangeRate);

        
        totalSupply = totalSupply + mintTokens;
        accountTokens[minter] = accountTokens[minter] + mintTokens;

        
        emit Mint(minter, actualMintAmount, mintTokens);
        emit Transfer(address(this), minter, mintTokens);

        
        
        
    }

    
    function redeemInternal(uint redeemTokens) internal nonReentrant {
        uint error = accrueInterest();
        if (error != NO_ERROR) {
            
            revert RedeemAccrueInterestFailed(error);
        }
        
        redeemFresh(payable(msg.sender), redeemTokens, 0);
    }

    
    function redeemUnderlyingInternal(uint redeemAmount) internal nonReentrant {
        uint error = accrueInterest();
        if (error != NO_ERROR) {
            
            revert RedeemAccrueInterestFailed(error);
        }
        
        redeemFresh(payable(msg.sender), 0, redeemAmount);
    }

    
    function redeemFresh(address payable redeemer, uint redeemTokensIn, uint redeemAmountIn) internal {
        require(redeemTokensIn == 0 || redeemAmountIn == 0, "one of redeemTokensIn or redeemAmountIn must be zero");

        
        Exp memory exchangeRate = Exp({mantissa: exchangeRateStoredInternal() });

        uint redeemTokens;
        uint redeemAmount;
        
        if (redeemTokensIn > 0) {
            
            redeemTokens = redeemTokensIn;
            redeemAmount = mul_ScalarTruncate(exchangeRate, redeemTokensIn);
        } else {
            
            redeemTokens = div_(redeemAmountIn, exchangeRate);
            redeemAmount = redeemAmountIn;
        }

        
        uint allowed = comptroller.redeemAllowed(address(this), redeemer, redeemTokens);
        if (allowed != 0) {
            revert RedeemComptrollerRejection(allowed);
        }

        
        if (accrualBlockNumber != getBlockNumber()) {
            revert RedeemFreshnessCheck();
        }

        
        if (getCashPrior() < redeemAmount) {
            revert RedeemTransferOutNotPossible();
        }

        
        
        


        
        totalSupply = totalSupply - redeemTokens;
        accountTokens[redeemer] = accountTokens[redeemer] - redeemTokens;

        
        doTransferOut(redeemer, redeemAmount);

        
        emit Transfer(redeemer, address(this), redeemTokens);
        emit Redeem(redeemer, redeemAmount, redeemTokens);

        
        comptroller.redeemVerify(address(this), redeemer, redeemAmount, redeemTokens);
    }

    
    function borrowInternal(uint borrowAmount) internal nonReentrant {
        uint error = accrueInterest();
        if (error != NO_ERROR) {
            
            revert BorrowAccrueInterestFailed(error);
        }
        
        borrowFresh(payable(msg.sender), borrowAmount);
    }

    
    function borrowFresh(address payable borrower, uint borrowAmount) internal {
        
        uint allowed = comptroller.borrowAllowed(address(this), borrower, borrowAmount);
        if (allowed != 0) {
            revert BorrowComptrollerRejection(allowed);
        }

        
        if (accrualBlockNumber != getBlockNumber()) {
            revert BorrowFreshnessCheck();
        }

        
        if (getCashPrior() < borrowAmount) {
            revert BorrowCashNotAvailable();
        }

        
        uint accountBorrowsPrev = borrowBalanceStoredInternal(borrower);
        uint accountBorrowsNew = accountBorrowsPrev + borrowAmount;
        uint totalBorrowsNew = totalBorrows + borrowAmount;

        
        
        

        
        accountBorrows[borrower].principal = accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = totalBorrowsNew;

        
        doTransferOut(borrower, borrowAmount);

        
        emit Borrow(borrower, borrowAmount, accountBorrowsNew, totalBorrowsNew);
    }

    
    function repayBorrowInternal(uint repayAmount) internal nonReentrant {
        uint error = accrueInterest();
        if (error != NO_ERROR) {
            
            revert RepayBorrowAccrueInterestFailed(error);
        }
        
        repayBorrowFresh(msg.sender, msg.sender, repayAmount);
    }

    
    function repayBorrowBehalfInternal(address borrower, uint repayAmount) internal nonReentrant {
        uint error = accrueInterest();
        if (error != NO_ERROR) {
            
            revert RepayBehalfAccrueInterestFailed(error);
        }
        
        repayBorrowFresh(msg.sender, borrower, repayAmount);
    }

    
    function repayBorrowFresh(address payer, address borrower, uint repayAmount) internal returns (uint) {
        
        uint allowed = comptroller.repayBorrowAllowed(address(this), payer, borrower, repayAmount);
        if (allowed != 0) {
            revert RepayBorrowComptrollerRejection(allowed);
        }

        
        if (accrualBlockNumber != getBlockNumber()) {
            revert RepayBorrowFreshnessCheck();
        }

        
        uint accountBorrowsPrev = borrowBalanceStoredInternal(borrower);

        
        uint repayAmountFinal = repayAmount == type(uint).max ? accountBorrowsPrev : repayAmount;

        
        
        

        
        uint actualRepayAmount = doTransferIn(payer, repayAmountFinal);

        
        uint accountBorrowsNew = accountBorrowsPrev - actualRepayAmount;
        uint totalBorrowsNew = totalBorrows - actualRepayAmount;

        
        accountBorrows[borrower].principal = accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = totalBorrowsNew;

        
        emit RepayBorrow(payer, borrower, actualRepayAmount, accountBorrowsNew, totalBorrowsNew);

        return actualRepayAmount;
    }

    
    function liquidateBorrowInternal(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) internal nonReentrant {
        uint error = accrueInterest();
        if (error != NO_ERROR) {
            
            revert LiquidateAccrueBorrowInterestFailed(error);
        }

        error = cTokenCollateral.accrueInterest();
        if (error != NO_ERROR) {
            
            revert LiquidateAccrueCollateralInterestFailed(error);
        }

        
        liquidateBorrowFresh(msg.sender, borrower, repayAmount, cTokenCollateral);
    }

    
    function liquidateBorrowFresh(address liquidator, address borrower, uint repayAmount, CTokenInterface cTokenCollateral) internal {
        
        uint allowed = comptroller.liquidateBorrowAllowed(address(this), address(cTokenCollateral), liquidator, borrower, repayAmount);
        if (allowed != 0) {
            revert LiquidateComptrollerRejection(allowed);
        }

        
        if (accrualBlockNumber != getBlockNumber()) {
            revert LiquidateFreshnessCheck();
        }

        
        if (cTokenCollateral.accrualBlockNumber() != getBlockNumber()) {
            revert LiquidateCollateralFreshnessCheck();
        }

        
        if (borrower == liquidator) {
            revert LiquidateLiquidatorIsBorrower();
        }

        
        if (repayAmount == 0) {
            revert LiquidateCloseAmountIsZero();
        }

        
        if (repayAmount == type(uint).max) {
            revert LiquidateCloseAmountIsUintMax();
        }

        
        uint actualRepayAmount = repayBorrowFresh(liquidator, borrower, repayAmount);

        
        
        

        
        (uint amountSeizeError, uint seizeTokens) = comptroller.liquidateCalculateSeizeTokens(address(this), address(cTokenCollateral), actualRepayAmount);
        require(amountSeizeError == NO_ERROR, "LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED");

        
        require(cTokenCollateral.balanceOf(borrower) >= seizeTokens, "LIQUIDATE_SEIZE_TOO_MUCH");

        
        if (address(cTokenCollateral) == address(this)) {
            seizeInternal(address(this), liquidator, borrower, seizeTokens);
        } else {
            require(cTokenCollateral.seize(liquidator, borrower, seizeTokens) == NO_ERROR, "token seizure failed");
        }

        
        emit LiquidateBorrow(liquidator, borrower, actualRepayAmount, address(cTokenCollateral), seizeTokens);
    }

    
    function seize(address liquidator, address borrower, uint seizeTokens) override external nonReentrant returns (uint) {
        seizeInternal(msg.sender, liquidator, borrower, seizeTokens);

        return NO_ERROR;
    }

    
    function seizeInternal(address seizerToken, address liquidator, address borrower, uint seizeTokens) internal {
        
        uint allowed = comptroller.seizeAllowed(address(this), seizerToken, liquidator, borrower, seizeTokens);
        if (allowed != 0) {
            revert LiquidateSeizeComptrollerRejection(allowed);
        }

        
        if (borrower == liquidator) {
            revert LiquidateSeizeLiquidatorIsBorrower();
        }

        
        uint protocolSeizeTokens = mul_(seizeTokens, Exp({mantissa: protocolSeizeShareMantissa}));
        uint liquidatorSeizeTokens = seizeTokens - protocolSeizeTokens;
        Exp memory exchangeRate = Exp({mantissa: exchangeRateStoredInternal()});
        uint protocolSeizeAmount = mul_ScalarTruncate(exchangeRate, protocolSeizeTokens);
        uint totalReservesNew = totalReserves + protocolSeizeAmount;


        
        
        

        
        totalReserves = totalReservesNew;
        totalSupply = totalSupply - protocolSeizeTokens;
        accountTokens[borrower] = accountTokens[borrower] - seizeTokens;
        accountTokens[liquidator] = accountTokens[liquidator] + liquidatorSeizeTokens;

        
        emit Transfer(borrower, liquidator, liquidatorSeizeTokens);
        emit Transfer(borrower, address(this), protocolSeizeTokens);
        emit ReservesAdded(address(this), protocolSeizeAmount, totalReservesNew);
    }


    

    
    function _setPendingAdmin(address payable newPendingAdmin) override external returns (uint) {
        
        if (msg.sender != admin) {
            revert SetPendingAdminOwnerCheck();
        }

        
        address oldPendingAdmin = pendingAdmin;

        
        pendingAdmin = newPendingAdmin;

        
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return NO_ERROR;
    }

    
    function _acceptAdmin() override external returns (uint) {
        
        if (msg.sender != pendingAdmin || msg.sender == address(0)) {
            revert AcceptAdminPendingAdminCheck();
        }

        
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        
        admin = pendingAdmin;

        
        pendingAdmin = payable(address(0));

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

        return NO_ERROR;
    }

    
    
    function _setComptroller(ComptrollerInterface newComptroller) override public returns (uint) {
        
        if (msg.sender != admin) {
            revert SetComptrollerOwnerCheck();
        }

        ComptrollerInterface oldComptroller = comptroller;
        
        require(newComptroller.isComptroller(), "marker method returned false");

        
        comptroller = newComptroller;

        
        emit NewComptroller(oldComptroller, newComptroller);

        return NO_ERROR;
    }

    
    function _setReserveFactor(uint newReserveFactorMantissa) override external nonReentrant returns (uint) {
        uint error = accrueInterest();
        if (error != NO_ERROR) {
            
            revert SetReserveFactorAccrueInterestFailed(error);
        }
        
        return _setReserveFactorFresh(newReserveFactorMantissa);
    }

    
    function _setReserveFactorFresh(uint newReserveFactorMantissa) internal returns (uint) {
        
        if (msg.sender != admin) {
            revert SetReserveFactorAdminCheck();
        }

        
        if (accrualBlockNumber != getBlockNumber()) {
            revert SetReserveFactorFreshCheck();
        }

        
        if (newReserveFactorMantissa > reserveFactorMaxMantissa) {
            revert SetReserveFactorBoundsCheck();
        }

        uint oldReserveFactorMantissa = reserveFactorMantissa;
        reserveFactorMantissa = newReserveFactorMantissa;

        emit NewReserveFactor(oldReserveFactorMantissa, newReserveFactorMantissa);

        return NO_ERROR;
    }

    
    function _addReservesInternal(uint addAmount) internal nonReentrant returns (uint) {
        uint error = accrueInterest();
        if (error != NO_ERROR) {
            
            revert AddReservesAccrueInterestFailed(error);
        }

        
        (error, ) = _addReservesFresh(addAmount);
        return error;
    }

    
    function _addReservesFresh(uint addAmount) internal returns (uint, uint) {
        
        uint totalReservesNew;
        uint actualAddAmount;

        
        if (accrualBlockNumber != getBlockNumber()) {
            revert AddReservesFactorFreshCheck(actualAddAmount);
        }

        
        
        

        

        actualAddAmount = doTransferIn(msg.sender, addAmount);

        totalReservesNew = totalReserves + actualAddAmount;

        
        totalReserves = totalReservesNew;

        
        emit ReservesAdded(msg.sender, actualAddAmount, totalReservesNew);

        
        return (NO_ERROR, actualAddAmount);
    }


    
    function _reduceReserves(uint reduceAmount) override external nonReentrant returns (uint) {
        uint error = accrueInterest();
        if (error != NO_ERROR) {
            
            revert ReduceReservesAccrueInterestFailed(error);
        }
        
        return _reduceReservesFresh(reduceAmount);
    }

    
    function _reduceReservesFresh(uint reduceAmount) internal returns (uint) {
        
        uint totalReservesNew;

        
        if (msg.sender != admin) {
            revert ReduceReservesAdminCheck();
        }

        
        if (accrualBlockNumber != getBlockNumber()) {
            revert ReduceReservesFreshCheck();
        }

        
        if (getCashPrior() < reduceAmount) {
            revert ReduceReservesCashNotAvailable();
        }

        
        if (reduceAmount > totalReserves) {
            revert ReduceReservesCashValidation();
        }

        
        
        

        totalReservesNew = totalReserves - reduceAmount;

        
        totalReserves = totalReservesNew;

        
        doTransferOut(admin, reduceAmount);

        emit ReservesReduced(admin, reduceAmount, totalReservesNew);

        return NO_ERROR;
    }

    
    function _setInterestRateModel(InterestRateModel newInterestRateModel) override public returns (uint) {
        uint error = accrueInterest();
        if (error != NO_ERROR) {
            
            revert SetInterestRateModelAccrueInterestFailed(error);
        }
        
        return _setInterestRateModelFresh(newInterestRateModel);
    }

    
    function _setInterestRateModelFresh(InterestRateModel newInterestRateModel) internal returns (uint) {

        
        InterestRateModel oldInterestRateModel;

        
        if (msg.sender != admin) {
            revert SetInterestRateModelOwnerCheck();
        }

        
        if (accrualBlockNumber != getBlockNumber()) {
            revert SetInterestRateModelFreshCheck();
        }

        
        oldInterestRateModel = interestRateModel;

        
        require(newInterestRateModel.isInterestRateModel(), "marker method returned false");

        
        interestRateModel = newInterestRateModel;

        
        emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);

        return NO_ERROR;
    }

    

    
    function getCashPrior() virtual internal view returns (uint);

    
    function doTransferIn(address from, uint amount) virtual internal returns (uint);

    
    function doTransferOut(address payable to, uint amount) virtual internal;


    

    
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; 
    }
}
