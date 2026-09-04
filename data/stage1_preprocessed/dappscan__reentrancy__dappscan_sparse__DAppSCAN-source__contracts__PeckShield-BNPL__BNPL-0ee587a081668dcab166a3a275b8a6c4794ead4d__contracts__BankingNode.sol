

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/ILendingPoolAddressesProvider.sol";
import "./interfaces/IAaveIncentivesController.sol";
import "./libraries/UniswapV2Library.sol";
import "./libraries/TransferHelper.sol";




error InvalidUser(address requiredUser);

error NodeInactive();

error KYCNotApproved();

error NoPrincipalRemaining();

error ZeroInput();

error InvalidLoanInput();

error MaximumLoanDurationExceeded();

error LoanStillOngoing();

error DonationRequired();

error ActiveLoansOngoing();

error InsufficientBalance();

error InsufficentOutput();

error LoanAlreadyStarted();

error InsufficientCollateral();

error LoanNotExpired();

error LoanAlreadySlashed();

error LoanStillUnbonding();

error InvalidCollateral();

contract BankingNode is ERC20("BNPL USD", "bUSD") {
    
    address public operator;
    address public baseToken; 
    uint256 public gracePeriod;
    bool public requireKYC;

    
    address private uniswapFactory;
    address private WETH;
    uint256 private incrementor;

    
    address public BNPL;
    ILendingPoolAddressesProvider public lendingPoolProvider;
    address public immutable bnplFactory;
    
    IAaveIncentivesController private aaveRewardController;
    address private treasury;

    
    mapping(uint256 => Loan) public idToLoan;
    uint256[] public pendingRequests;
    uint256[] public currentLoans;
    mapping(uint256 => uint256) defaultedLoans;
    uint256 public defaultedLoanCount;

    
    uint256 public accountsReceiveable;
    mapping(address => bool) public whitelistedAddresses;
    mapping(address => uint256) public unbondBlock;
    mapping(uint256 => address) public loanToAgent;
    uint256 public slashingBalance;
    mapping(address => uint256) public stakingShares;
    
    uint256 private totalStakingShares;

    uint256 public unbondingAmount;
    mapping(address => uint256) public unbondingShares;
    
    uint256 private totalUnbondingShares;

    
    mapping(address => uint256) public collateralOwed;

    struct Loan {
        address borrower;
        bool interestOnly; 
        uint256 loanStartTime; 
        uint256 loanAmount;
        uint256 paymentInterval; 
        uint256 interestRate; 
        uint256 numberOfPayments;
        uint256 principalRemaining;
        uint256 paymentsMade;
        address collateral;
        uint256 collateralAmount;
        bool isSlashed;
    }

    
    event LoanRequest(uint256 loanId, string message);
    event collateralWithdrawn(
        uint256 loanId,
        address collateral,
        uint256 collateralAmount
    );
    event approvedLoan(uint256 loanId);
    event loanPaymentMade(uint256 loanId);
    event loanRepaidEarly(uint256 loanId);
    event baseTokenDeposit(address user, uint256 amount);
    event baseTokenWithdrawn(address user, uint256 amount);
    event feesCollected(uint256 operatorFees, uint256 stakerFees);
    event baseTokensDonated(uint256 amount);
    event loanSlashed(uint256 loanId);
    event slashingSale(uint256 bnplSold, uint256 baseTokenRecovered);
    event bnplStaked(address user, uint256 bnplStaked);
    event unbondingInitiated(address user, uint256 unbondAmount);
    event bnplWithdrawn(address user, uint256 bnplWithdrawn);
    event KYCRequirementChanged(bool newStatus);

    constructor() {
        bnplFactory = msg.sender;
    }

    

    
    modifier ensureNodeActive() {
        address _operator = operator;
        if (msg.sender != bnplFactory && msg.sender != _operator) {
            if (getBNPLBalance(_operator) < 0x13DA329B6336471800000) {
                revert NodeInactive();
            }
            if (requireKYC && whitelistedAddresses[msg.sender] == false) {
                revert KYCNotApproved();
            }
        }
        _;
    }

    
    modifier ensurePrincipalRemaining(uint256 loanId) {
        if (idToLoan[loanId].principalRemaining == 0) {
            revert NoPrincipalRemaining();
        }
        _;
    }

    
    modifier operatorOnly() {
        address _operator = operator;
        if (msg.sender != _operator) {
            revert InvalidUser(_operator);
        }
        _;
    }

    
    modifier nonZeroInput(uint256 input) {
        if (input == 0) {
            revert ZeroInput();
        }
        _;
    }

    
    modifier nonBaseToken(address collateral) {
        if (collateral == baseToken) {
            revert InvalidCollateral();
        }
        _;
    }

    

    
    function initialize(
        address _baseToken,
        address _BNPL,
        bool _requireKYC,
        address _operator,
        uint256 _gracePeriod,
        address _lendingPoolProvider,
        address _WETH,
        address _aaveDistributionController,
        address _uniswapFactory
    ) external {
        
        require(msg.sender == bnplFactory);
        baseToken = _baseToken;
        BNPL = _BNPL;
        requireKYC = _requireKYC;
        operator = _operator;
        gracePeriod = _gracePeriod;
        lendingPoolProvider = ILendingPoolAddressesProvider(
            _lendingPoolProvider
        );
        aaveRewardController = IAaveIncentivesController(
            _aaveDistributionController
        );
        WETH = _WETH;
        uniswapFactory = _uniswapFactory;
        treasury = address(0x27a99802FC48b57670846AbFFf5F2DcDE8a6fC29);
        
        require(
            ERC20(_baseToken).decimals() ==
                ERC20(
                    _getLendingPool().getReserveData(_baseToken).aTokenAddress
                ).decimals()
        );
    }

    
    function requestLoan(
        uint256 loanAmount,
        uint256 paymentInterval,
        uint256 numberOfPayments,
        uint256 interestRate,
        bool interestOnly,
        address collateral,
        uint256 collateralAmount,
        address agent,
        string memory message
    )
        external
        ensureNodeActive
        nonBaseToken(collateral)
        returns (uint256 requestId)
    {
        if (loanAmount < 1000 || paymentInterval == 0 || interestRate == 0) {
            revert InvalidLoanInput();
        }
        
        if (paymentInterval * numberOfPayments > 157680000) {
            revert MaximumLoanDurationExceeded();
        }
        requestId = incrementor;
        incrementor++;
        pendingRequests.push(requestId);
        idToLoan[requestId] = Loan(
            msg.sender, 
            interestOnly,
            0, 
            loanAmount,
            paymentInterval, 
            interestRate, 
            numberOfPayments,
            0, 
            0, 
            collateral,
            collateralAmount,
            false
        );
        
        if (collateralAmount > 0) {
            
            collateralOwed[collateral] += collateralAmount;
            TransferHelper.safeTransferFrom(
                collateral,
                msg.sender,
                address(this),
                collateralAmount
            );
            
            _depositToLendingPool(collateral, collateralAmount);
        }
        
        loanToAgent[requestId] = agent;

        emit LoanRequest(requestId, message);
    }

    
    function withdrawCollateral(uint256 loanId) external {
        Loan storage loan = idToLoan[loanId];
        address collateral = loan.collateral;
        uint256 amount = loan.collateralAmount;

        
        if (msg.sender != loan.borrower) {
            revert InvalidUser(loan.borrower);
        }
        if (loan.principalRemaining > 0) {
            revert LoanStillOngoing();
        }
        
        _withdrawFromLendingPool(collateral, amount, loan.borrower);

        
        collateralOwed[collateral] -= amount;
        loan.collateralAmount = 0;

        emit collateralWithdrawn(loanId, collateral, amount);
    }

    
    function collectAaveRewards(address[] calldata assets) external {
        uint256 rewardAmount = aaveRewardController.getUserUnclaimedRewards(
            address(this)
        );
        address _treasuy = treasury;
        if (rewardAmount == 0) {
            revert ZeroInput();
        }
        
        aaveRewardController.claimRewards(assets, rewardAmount, _treasuy);
        
    }

    
    function collectCollateralFees(address collateral)
        external
        nonBaseToken(collateral)
    {
        
        ILendingPool lendingPool = _getLendingPool();
        address _bnpl = BNPL;
        uint256 feesAccrued = IERC20(
            lendingPool.getReserveData(collateral).aTokenAddress
        ).balanceOf(address(this)) - collateralOwed[collateral];
        
        lendingPool.withdraw(collateral, feesAccrued, address(this));
        
        _swapToken(collateral, _bnpl, 0, feesAccrued);
    }

    
    function makeLoanPayment(uint256 loanId)
        external
        ensurePrincipalRemaining(loanId)
    {
        Loan storage loan = idToLoan[loanId];
        uint256 paymentAmount = getNextPayment(loanId);
        uint256 interestPortion = (loan.principalRemaining *
            loan.interestRate) / 10000;
        address _baseToken = baseToken;
        loan.paymentsMade++;
        
        bool finalPayment = loan.paymentsMade == loan.numberOfPayments;

        if (!loan.interestOnly) {
            uint256 principalPortion = paymentAmount - interestPortion;
            loan.principalRemaining -= principalPortion;
            accountsReceiveable -= principalPortion;
        } else {
            
            if (finalPayment) {
                accountsReceiveable -= loan.principalRemaining;
                loan.principalRemaining = 0;
            }
        }
        
        TransferHelper.safeTransferFrom(
            _baseToken,
            msg.sender,
            address(this),
            paymentAmount
        );
        
        _depositToLendingPool(
            _baseToken,
            paymentAmount - ((interestPortion * 3) / 10)
        );
        
        if (finalPayment) {
            _removeCurrentLoan(loanId);
        }
        

        emit loanPaymentMade(loanId);
    }

    
    function repayEarly(uint256 loanId)
        external
        ensurePrincipalRemaining(loanId)
    {
        Loan storage loan = idToLoan[loanId];
        uint256 principalLeft = loan.principalRemaining;
        
        uint256 interestAmount = (principalLeft * loan.interestRate) / 10000;
        uint256 paymentAmount = principalLeft + interestAmount;
        address _baseToken = baseToken;
        
        TransferHelper.safeTransferFrom(
            _baseToken,
            msg.sender,
            address(this),
            paymentAmount
        );
        
        _depositToLendingPool(
            _baseToken,
            paymentAmount - ((interestAmount * 3) / 10)
        );

        
        accountsReceiveable -= principalLeft;
        loan.principalRemaining = 0;
        
        loan.paymentsMade = loan.numberOfPayments;
        _removeCurrentLoan(loanId);

        emit loanRepaidEarly(loanId);
    }
    
    
    function collectFees() external {
        
        
        address _baseToken = baseToken;
        address _bnpl = BNPL;
        address _operator = operator;
        uint256 _operatorFees = IERC20(_baseToken).balanceOf(address(this)) / 3;
        TransferHelper.safeTransfer(_baseToken, _operator, _operatorFees);
        
        
        uint256 _stakingRewards = _swapToken(
            _baseToken,
            _bnpl,
            0,
            IERC20(_baseToken).balanceOf(address(this))
        );
        emit feesCollected(_operatorFees, _stakingRewards);
    }

    
    function deposit(uint256 _amount)
        external
        ensureNodeActive
        nonZeroInput(_amount)
    {
        
        address _baseToken = baseToken;
        uint256 decimalAdjust = 1;
        uint256 tokenDecimals = ERC20(_baseToken).decimals();
        if (tokenDecimals != 18) {
            decimalAdjust = 10**(18 - tokenDecimals);
        }
        
        uint256 what = _amount * decimalAdjust;
        if (totalSupply() != 0) {
            
            
            
            what = (_amount * totalSupply()) / getTotalAssetValue();
        }
        
        TransferHelper.safeTransferFrom(
            _baseToken,
            msg.sender,
            address(this),
            _amount
        );
        _mint(msg.sender, what);

        _depositToLendingPool(_baseToken, _amount);

        emit baseTokenDeposit(msg.sender, _amount);
    }

    
    function withdraw(uint256 _amount) external nonZeroInput(_amount) {
        uint256 userBaseBalance = getBaseTokenBalance(msg.sender);
        if (userBaseBalance < _amount) {
            revert InsufficientBalance();
        }
        
        uint256 what = (_amount * totalSupply()) / getTotalAssetValue();
        address _baseToken = baseToken;
        _burn(msg.sender, what);
        
        _withdrawFromLendingPool(_baseToken, _amount, msg.sender);

        emit baseTokenWithdrawn(msg.sender, _amount);
    }

    
    function stake(uint256 _amount)
        external
        ensureNodeActive
        nonZeroInput(_amount)
    {
        address staker = msg.sender;
        
        if (msg.sender == bnplFactory) {
            staker = operator;
        }
        
        uint256 what = _amount;
        uint256 _totalStakingShares = totalStakingShares;
        if (_totalStakingShares > 0) {
            
            
            uint256 totalStakedBNPL = getStakedBNPL();
            if (totalStakedBNPL == 0) {
                revert DonationRequired();
            }
            what = (_amount * _totalStakingShares) / totalStakedBNPL;
        }
        
        address _bnpl = BNPL;
        TransferHelper.safeTransferFrom(
            _bnpl,
            msg.sender,
            address(this),
            _amount
        );
        
        stakingShares[staker] += what;
        totalStakingShares += what;

        emit bnplStaked(msg.sender, _amount);
    }

    
    function initiateUnstake(uint256 _amount) external nonZeroInput(_amount) {
        
        address _operator = operator;
        if (msg.sender == _operator && currentLoans.length > 0) {
            revert ActiveLoansOngoing();
        }
        uint256 stakingSharesUser = stakingShares[msg.sender];
        
        if (stakingShares[msg.sender] < _amount) {
            revert InsufficientBalance();
        }
        
        unbondBlock[msg.sender] = block.number;
        
        
        uint256 what = (_amount * getStakedBNPL()) / totalStakingShares;
        
        stakingShares[msg.sender] -= _amount;
        totalStakingShares -= _amount;
        
        uint256 _newUnbondingShares = what;
        uint256 _unbondingAmount = unbondingAmount;
        
        if (_unbondingAmount != 0) {
            _newUnbondingShares =
                (what * totalUnbondingShares) /
                _unbondingAmount;
        }
        
        unbondingShares[msg.sender] += _newUnbondingShares;
        totalUnbondingShares += _newUnbondingShares;
        unbondingAmount += what;

        emit unbondingInitiated(msg.sender, _amount);
    }
    
    
    function unstake() external {
        uint256 _userAmount = unbondingShares[msg.sender];
        if (_userAmount == 0) {
            revert ZeroInput();
        }
        
        if (block.number < unbondBlock[msg.sender] + 46523) {
            revert LoanStillUnbonding();
        }
        uint256 _unbondingAmount = unbondingAmount;
        uint256 _totalUnbondingShares = totalUnbondingShares;
        address _bnpl = BNPL;
        
        uint256 _what = (_userAmount * _unbondingAmount) /
            _totalUnbondingShares;
        
        TransferHelper.safeTransfer(_bnpl, msg.sender, _what);
        
        unbondingShares[msg.sender] = 0;
        unbondingAmount -= _what;

        emit bnplWithdrawn(msg.sender, _what);
    }

    
    function slashLoan(uint256 loanId, uint256 minOut)
        external
        ensurePrincipalRemaining(loanId)
    {
        
        Loan storage loan = idToLoan[loanId];

        
        if (loan.isSlashed) {
            revert LoanAlreadySlashed();
        }
        if (block.timestamp <= getNextDueDate(loanId) + gracePeriod) {
            revert LoanNotExpired();
        }

        
        uint256 _collateralPosted = loan.collateralAmount;
        uint256 baseTokenOut = 0;
        address _baseToken = baseToken;
        if (_collateralPosted > 0) {
            
            address _collateral = loan.collateral;
            
            _withdrawFromLendingPool(
                _collateral,
                _collateralPosted,
                address(this)
            );
            
            baseTokenOut = _swapToken(
                _collateral,
                _baseToken,
                minOut,
                _collateralPosted
            );
            
            _depositToLendingPool(_baseToken, baseTokenOut);
            
            collateralOwed[_collateral] -= _collateralPosted;
            loan.collateralAmount = 0;
        }
        
        uint256 principalLost = loan.principalRemaining;
        
        if (baseTokenOut >= principalLost) {
            
            _withdrawFromLendingPool(
                _baseToken,
                baseTokenOut - principalLost,
                loan.borrower
            );
        }
        
        else {
            
            uint256 slashPercent = (1e12 * (principalLost - baseTokenOut)) /
                getTotalAssetValue();
            uint256 unbondingSlash = (unbondingAmount * slashPercent) / 1e12;
            uint256 stakingSlash = (getStakedBNPL() * slashPercent) / 1e12;
            
            accountsReceiveable -= principalLost;
            slashingBalance += unbondingSlash + stakingSlash;
            unbondingAmount -= unbondingSlash;
        }

        
        loan.isSlashed = true;
        _removeCurrentLoan(loanId);
        defaultedLoans[defaultedLoanCount] = loanId;
        defaultedLoanCount++;

        emit loanSlashed(loanId);
    }

    
    function sellSlashed(uint256 minOut) external {
        
        address _baseToken = baseToken;
        address _bnpl = BNPL;
        uint256 _slashingBalance = slashingBalance;
        
        if (_slashingBalance == 0) {
            revert ZeroInput();
        }
        
        uint256 baseTokenOut = _swapToken(
            _bnpl,
            _baseToken,
            minOut,
            _slashingBalance
        );
        
        _depositToLendingPool(_baseToken, baseTokenOut);
        slashingBalance = 0;

        emit slashingSale(_slashingBalance, baseTokenOut);
    }

    
    function donateBaseToken(uint256 _amount) external nonZeroInput(_amount) {
        
        address _baseToken = baseToken;
        
        TransferHelper.safeTransferFrom(
            _baseToken,
            msg.sender,
            address(this),
            _amount
        );
        
        _depositToLendingPool(_baseToken, _amount);

        emit baseTokensDonated(_amount);
    }

    

    
    function approveLoan(uint256 loanId, uint256 requiredCollateralAmount)
        external
        operatorOnly
    {
        Loan storage loan = idToLoan[loanId];
        uint256 length = pendingRequests.length;
        uint256 loanSize = loan.loanAmount;
        address _baseToken = baseToken;

        if (getBNPLBalance(operator) < 0x13DA329B6336471800000) {
            revert NodeInactive();
        }
        
        if (loan.loanStartTime > 0) {
            revert LoanAlreadyStarted();
        }
        if (loan.collateralAmount < requiredCollateralAmount) {
            revert InsufficientCollateral();
        }

        

        for (uint256 i = 0; i < length; i++) {
            if (loanId == pendingRequests[i]) {
                pendingRequests[i] = pendingRequests[length - 1];
                pendingRequests.pop();
                break;
            }
        }

        currentLoans.push(loanId);

        

        loan.principalRemaining = loanSize;
        loan.loanStartTime = block.timestamp;
        accountsReceiveable += loanSize;
        

        _withdrawFromLendingPool(
            _baseToken,
            (loanSize * 397) / 400,
            loan.borrower
        );
        
        _withdrawFromLendingPool(_baseToken, loanSize / 200, treasury);
        _withdrawFromLendingPool(
            _baseToken,
            loanSize / 400,
            loanToAgent[loanId]
        );

        emit approvedLoan(loanId);
    }

    
    function clearPendingLoans() external operatorOnly {
        pendingRequests = new uint256[](0);
    }

    
    function whitelistAddresses(
        address[] memory whitelistAddition,
        bool _status
    ) external operatorOnly {
        uint256 length = whitelistAddition.length;
        for (uint256 i; i < length; i++) {
            address newWhistelist = whitelistAddition[i];
            whitelistedAddresses[newWhistelist] = _status;
        }
    }

    
    function setKYC(bool _newStatus) external operatorOnly {
        requireKYC = _newStatus;
        emit KYCRequirementChanged(_newStatus);
    }

    

    
    function _depositToLendingPool(address tokenIn, uint256 amountIn) private {
        TransferHelper.safeApprove(
            tokenIn,
            address(_getLendingPool()),
            amountIn
        );
        _getLendingPool().deposit(tokenIn, amountIn, address(this), 0);
    }

    
    function _withdrawFromLendingPool(
        address tokenOut,
        uint256 amountOut,
        address to
    ) private nonZeroInput(amountOut) {
        _getLendingPool().withdraw(tokenOut, amountOut, to);
    }

    
    function _getLendingPool() private view returns (ILendingPool) {
        return ILendingPool(lendingPoolProvider.getLendingPool());
    }

    
    function _removeCurrentLoan(uint256 loanId) private {
        for (uint256 i = 0; i < currentLoans.length; i++) {
            if (loanId == currentLoans[i]) {
                currentLoans[i] = currentLoans[currentLoans.length - 1];
                currentLoans.pop();
                return;
            }
        }
    }

    
    function _swapToken(
        address tokenIn,
        address tokenOut,
        uint256 minOut,
        uint256 amountIn
    ) private returns (uint256 tokenOutput) {
        if (amountIn == 0) {
            revert ZeroInput();
        }
        
        address _uniswapFactory = uniswapFactory;
        address _weth = WETH;
        address pair1 = UniswapV2Library.pairFor(
            _uniswapFactory,
            tokenIn,
            _weth
        );
        address pair2 = UniswapV2Library.pairFor(
            _uniswapFactory,
            _weth,
            tokenOut
        );
        
        if (tokenIn == _weth) {
            pair1 = pair2;
            tokenOutput = amountIn;
        }
        
        TransferHelper.safeTransfer(tokenIn, pair1, amountIn);
        
        if (tokenIn != _weth) {
            tokenOutput = _swap(tokenIn, _weth, amountIn, pair1, pair2);
        }
        
        tokenOutput = _swap(_weth, tokenOut, tokenOutput, pair2, address(this));
        
        if (minOut > tokenOutput) {
            revert InsufficentOutput();
        }
    }

    
    function _swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address pair,
        address to
    ) private returns (uint256 tokenOutput) {
        address _uniswapFactory = uniswapFactory;
        
        (uint256 reserveIn, uint256 reserveOut) = UniswapV2Library.getReserves(
            _uniswapFactory,
            tokenIn,
            tokenOut
        );
        
        tokenOutput = UniswapV2Library.getAmountOut(
            amountIn,
            reserveIn,
            reserveOut
        );
        
        (address token0, ) = UniswapV2Library.sortTokens(tokenIn, tokenOut);
        (uint256 amount0Out, uint256 amount1Out) = tokenIn == token0
            ? (uint256(0), tokenOutput)
            : (tokenOutput, uint256(0));
        
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, to, new bytes(0));
    }

    

    
    function getStakedBNPL() public view returns (uint256) {
        return
            IERC20(BNPL).balanceOf(address(this)) -
            unbondingAmount -
            slashingBalance;
    }

    
    function getBaseTokenBalance(address user) public view returns (uint256) {
        uint256 _balance = balanceOf(user);
        if (totalSupply() == 0) {
            return 0;
        }
        return (_balance * getTotalAssetValue()) / totalSupply();
    }

    
    function getBNPLBalance(address user) public view returns (uint256 what) {
        uint256 _balance = stakingShares[user];
        uint256 _totalStakingShares = totalStakingShares;
        if (_totalStakingShares == 0) {
            what = 0;
        } else {
            what = (_balance * getStakedBNPL()) / _totalStakingShares;
        }
    }

    
    function getUnbondingBalance(address user) external view returns (uint256) {
        uint256 _totalUnbondingShares = totalUnbondingShares;
        uint256 _userUnbondingShare = unbondingShares[user];
        if (_totalUnbondingShares == 0) {
            return 0;
        }
        return (_userUnbondingShare * unbondingAmount) / _totalUnbondingShares;
    }

    
    function getNextPayment(uint256 loanId) public view returns (uint256) {
        
        Loan storage loan = idToLoan[loanId];
        if (loan.principalRemaining == 0) {
            return 0;
        }
        uint256 _interestRate = loan.interestRate;
        uint256 _loanAmount = loan.loanAmount;
        uint256 _numberOfPayments = loan.numberOfPayments;
        
        if (loan.interestOnly) {
            
            if (loan.paymentsMade + 1 == _numberOfPayments) {
                
                return _loanAmount + ((_loanAmount * _interestRate) / 10000);
            } else {
                
                return (_loanAmount * _interestRate) / 10000;
            }
        } else {
            
            
            
            
            
            uint256 numerator = _loanAmount *
                _interestRate *
                (10000 + _interestRate)**_numberOfPayments;
            uint256 denominator = (10000 + _interestRate)**_numberOfPayments -
                (10**(4 * _numberOfPayments));
            return numerator / (denominator * 10000);
        }
    }

    
    function getNextDueDate(uint256 loanId) public view returns (uint256) {
        
        Loan storage loan = idToLoan[loanId];
        if (loan.principalRemaining == 0) {
            return 0;
        }
        return
            loan.loanStartTime +
            ((loan.paymentsMade + 1) * loan.paymentInterval);
    }

    
    function getTotalAssetValue() public view returns (uint256) {
        return
            IERC20(_getLendingPool().getReserveData(baseToken).aTokenAddress)
                .balanceOf(address(this)) + accountsReceiveable;
    }

    
    function getPendingRequestCount() external view returns (uint256) {
        return pendingRequests.length;
    }

    
    function getCurrentLoansCount() external view returns (uint256) {
        return currentLoans.length;
    }
}
