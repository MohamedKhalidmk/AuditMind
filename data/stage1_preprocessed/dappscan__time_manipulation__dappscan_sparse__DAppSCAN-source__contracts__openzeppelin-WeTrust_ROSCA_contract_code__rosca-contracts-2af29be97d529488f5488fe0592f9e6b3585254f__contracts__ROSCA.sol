

pragma solidity ^0.4.4;


contract ROSCA {

  
  
  
  uint64 constant internal MIN_CONTRIBUTION_SIZE = 1 finney;  
  uint128 constant internal MAX_CONTRIBUTION_SIZE = 10 ether;

  
  uint16 constant internal MAX_FEE_IN_THOUSANDTHS = 20;

  
  uint32 constant internal MINIMUM_TIME_BEFORE_ROSCA_START = 1 days;

  uint8 constant internal MIN_ROUND_PERIOD_IN_DAYS = 1;
  uint8 constant internal MAX_ROUND_PERIOD_IN_DAYS = 30;
  
  uint8 constant internal MIN_DISTRIBUTION_PERCENT = 65;

  
  uint8 constant internal MAX_NEXT_BID_RATIO = 98;

  
  
  
  address constant internal FEE_ADDRESS = 0x1df62f291b2e969fb0849d99d9ce41e2f137006e;

  
  
  
  address constant internal ESCAPE_HATCH_ENABLER = 0x1df62f291b2e969fb0849d99d9ce41e2f137006e;

  
  
  
  event LogContributionMade(address user, uint256 amount);
  event LogStartOfRound(uint256 currentRound);
  event LogNewLowestBid(uint256 bid,address winnerAddress);
  event LogRoundFundsReleased(address winnerAddress, uint256 amountInWei);
  event LogRoundNoWinner(uint256 currentRound);
  event LogFundsWithdrawal(address user, uint256 amount);
  event LogForepersonSurplusWithdrawal(uint256 amount);
  
  
  
  event LogCannotWithdrawFully(uint256 creditAmount);
  event LogUnsuccessfulBid(address bidder,uint256 bidInWei,uint256 lowestBid);
  event LogEndOfROSCA();

  
  event LogEscapeHatchEnabled();
  event LogEscapeHatchActivated();
  event LogEmergencyWithdrawalPerformed(uint256 fundsDispersed);

  
  
  

  
  uint16 internal roundPeriodInDays;
  uint16 internal serviceFeeInThousandths;
  uint16 internal currentRound;  
  address internal foreperson;
  uint128 internal contributionSize;
  uint256 internal startTime;

  
  bool internal endOfROSCA = false;
  bool internal forepersonSurplusCollected = false;
  
  
  uint256 internal totalDiscounts = 0;

  
  uint256 internal totalFees = 0;

  
  uint256 internal lowestBid = 0;
  address internal winnerAddress = 0;  

  mapping(address => User) internal members;
  address[] internal membersAddresses;  

  
  
  
  
  
  
  
  
  bool internal escapeHatchEnabled = false;
  bool internal escapeHatchActive = false;

  struct User {
    uint256 credit;  
    bool debt; 
    bool paid; 
    bool alive; 
  }

  
  
  
  modifier onlyFromMember {
    if (!members[msg.sender].alive) {
      throw;
    }
    _;
  }

  modifier onlyFromForeperson {
    if (msg.sender != foreperson) {
      throw;
    }
    _;
  }

  modifier onlyFromFeeAddress {
    if (msg.sender != FEE_ADDRESS) {
      throw;
    }
    _;
  }

  modifier roscaNotEnded {
    if (endOfROSCA) {
      throw;
    }
    _;
  }

  modifier roscaEnded {
    if (!endOfROSCA) {
      throw;
    }
    _;
  }

  modifier onlyIfEscapeHatchActive {
    if (!escapeHatchActive) {
      throw;
    }
    _;
  }

  modifier onlyIfEscapeHatchInactive {
    if (escapeHatchActive) {
      throw;
    }
    _;
  }

  modifier onlyFromEscapeHatchEnabler {
    if (msg.sender != ESCAPE_HATCH_ENABLER) {
      throw;
    }
    _;
  }

  
  
  

  
  function ROSCA (
      uint16 roundPeriodInDays_,
      uint128 contributionSize_,
      uint256 startTime_,
      address[] members_,
      uint16 serviceFeeInThousandths_) {
    if (roundPeriodInDays_ < MIN_ROUND_PERIOD_IN_DAYS || roundPeriodInDays_ > MAX_ROUND_PERIOD_IN_DAYS) {
      throw;
    }
    roundPeriodInDays = roundPeriodInDays_;

    if (contributionSize_ < MIN_CONTRIBUTION_SIZE || contributionSize_ > MAX_CONTRIBUTION_SIZE) {
      throw;
    }
    contributionSize = contributionSize_;
    
    if (startTime_ < (now + MINIMUM_TIME_BEFORE_ROSCA_START)) {
      throw;
    }
    startTime = startTime_;
    if (serviceFeeInThousandths_ > MAX_FEE_IN_THOUSANDTHS) {
      throw;
    }
    serviceFeeInThousandths = serviceFeeInThousandths_;

    foreperson = msg.sender;
    addMember(msg.sender);

    for (uint16 i = 0; i < members_.length; i++) {
      addMember(members_[i]);
    }
  }

  function addMember(address newMember) internal {
    if (members[newMember].alive) {  
      throw;
    }
    members[newMember] = User({paid: false , credit: 0, alive: true, debt: false});
    membersAddresses.push(newMember);
  }

  
  function startRound() roscaNotEnded external {
    uint256 roundStartTime = startTime + (uint(currentRound)  * roundPeriodInDays * 1 days);
    if (now < roundStartTime ) {  
      throw;
    }

    if (currentRound != 0) {
      cleanUpPreviousRound();
    }
    if (currentRound < membersAddresses.length) {
      lowestBid = 0;
      winnerAddress = 0;
      currentRound++;
      LogStartOfRound(currentRound);
    } else {
        endOfROSCA = true;
        LogEndOfROSCA();
    }
  }

  function cleanUpPreviousRound() internal {
    address delinquentWinner = 0x0;
    uint256 winnerIndex;
    bool winnerSelectedThroughBid = (winnerAddress != 0);
    uint16 numUnpaidParticipants = uint16(membersAddresses.length) - (currentRound - 1);
    if (winnerAddress == 0) {
      
      
      
      
      uint256 semi_random = now % numUnpaidParticipants;
      for (uint16 i = 0; i < numUnpaidParticipants; i++) {
        uint256 index = (semi_random + i) % numUnpaidParticipants;
        address candidate = membersAddresses[index];
        if (!members[candidate].paid) {
          winnerIndex = index;
          if (members[candidate].credit + totalDiscounts >= (currentRound * contributionSize)) {
            
            winnerAddress = candidate;
            break;
          }
          delinquentWinner = candidate;
        }
      }
      if (winnerAddress == 0) {  
        
        if (delinquentWinner == 0 || members[delinquentWinner].paid) throw;
        winnerAddress = delinquentWinner;
        
        members[winnerAddress].debt = true;
      }
      
      lowestBid = contributionSize * membersAddresses.length;
    }
    
    
    
    swapWinner(winnerIndex, winnerSelectedThroughBid, numUnpaidParticipants - 1);
    
    uint256 currentRoundTotalDiscounts = removeFees(contributionSize * membersAddresses.length - lowestBid);
    totalDiscounts += currentRoundTotalDiscounts / membersAddresses.length;
    members[winnerAddress].credit += removeFees(lowestBid);
    members[winnerAddress].paid = true;
    LogRoundFundsReleased(winnerAddress, lowestBid);
    recalculateTotalFees();
  }

  
  function recalculateTotalFees() {
    
    
    uint256 requiredContributions = currentRound * contributionSize;
    uint256 grossTotalFees = requiredContributions * membersAddresses.length;

    for (uint16 j = 0; j < membersAddresses.length; j++) {
      User member = members[membersAddresses[j]];
      uint256 credit = member.credit;
      uint256 debit = requiredContributions;
      if (member.debt) {
        
        
        debit += removeFees(membersAddresses.length * contributionSize);
      }
      if (credit + totalDiscounts < debit) {
        grossTotalFees -= debit - credit - totalDiscounts;
      }
    }
    
    totalFees = grossTotalFees * serviceFeeInThousandths / 1000;
  }

  
  
  function swapWinner(
    uint256 winnerIndex, bool winnerSelectedThroughBid, uint256 indexToSwap) internal {
    if (winnerSelectedThroughBid) {
      
      
      for (uint16 i = 0; i <= indexToSwap; i++) {
        if (membersAddresses[i] == winnerAddress) {
          winnerIndex = i;
          break;
        }
      }
    }
    
    membersAddresses[winnerIndex] = membersAddresses[indexToSwap];
    membersAddresses[indexToSwap] = winnerAddress;
  }

  
  function removeFees(uint256 amount) internal returns (uint256) {
    
    
    return amount * (1000 - serviceFeeInThousandths) / 1000;
  }

  
  function contribute() payable onlyFromMember roscaNotEnded onlyIfEscapeHatchInactive external {
    User member = members[msg.sender];
    member.credit += msg.value;
    if (member.debt) {
      
      
      
      
      uint256 requiredContributions = currentRound * contributionSize;
      if (member.credit + totalDiscounts - removeFees(membersAddresses.length * contributionSize) >= requiredContributions) {
          member.debt = false;
      }
    }

    LogContributionMade(msg.sender, msg.value);
  }

  
  function bid(uint256 bidInWei) onlyFromMember roscaNotEnded onlyIfEscapeHatchInactive external {
    if (members[msg.sender].paid  ||
        currentRound == 0 ||  
        
        members[msg.sender].credit + totalDiscounts < (currentRound * contributionSize) ||
        
        
        bidInWei < contributionSize * membersAddresses.length * MIN_DISTRIBUTION_PERCENT / 100) {
      throw;
    }

    
    
    
    uint256 maxAllowedBid = winnerAddress == 0
        ? contributionSize * membersAddresses.length
        : lowestBid * MAX_NEXT_BID_RATIO / 100;
    if (bidInWei > maxAllowedBid) {
      
      
      
      LogUnsuccessfulBid(msg.sender, bidInWei, lowestBid);
      return;
    }
    lowestBid = bidInWei;
    winnerAddress = msg.sender;
    LogNewLowestBid(lowestBid, winnerAddress);
  }

  
  function withdraw() onlyFromMember onlyIfEscapeHatchInactive external returns(bool success) {
    if (members[msg.sender].debt && !endOfROSCA) {  
      throw;
    }
    uint256 totalCredit = members[msg.sender].credit + totalDiscounts;

    uint256 totalDebit = members[msg.sender].debt
        ? removeFees(membersAddresses.length * contributionSize)  
        : currentRound * contributionSize;
    if (totalDebit >= totalCredit) {  
        throw;
    }

    uint256 amountToWithdraw = totalCredit - totalDebit;
    uint256 amountAvailable = this.balance - totalFees;

    if (amountAvailable < amountToWithdraw) {
      
      LogCannotWithdrawFully(amountToWithdraw);
      amountToWithdraw = amountAvailable;
    }
    members[msg.sender].credit -= amountToWithdraw;
    if (!msg.sender.send(amountToWithdraw)) {   
      
      
      members[msg.sender].credit += amountToWithdraw;
      return false;
    }
    LogFundsWithdrawal(msg.sender, amountToWithdraw);
    return true;
  }

  
  
  function getParticipantBalance(address user) onlyFromMember external constant returns(int256) {
    int256 totalCredit = int256(members[user].credit + totalDiscounts);

    
    if (members[user].debt && !endOfROSCA) {
        totalCredit -= int256(removeFees(membersAddresses.length * contributionSize));
    }
    int256 totalDebit = int256(currentRound * contributionSize);

    return totalCredit - totalDebit;
  }
  

  
  function getContractNetBalance() external constant returns(uint256) {
    return this.balance - totalFees;
  }

  
  function endOfROSCARetrieveSurplus() onlyFromForeperson roscaEnded external returns (bool) {
    uint256 roscaCollectionTime = startTime + ((membersAddresses.length + 1) * roundPeriodInDays * 1 days);
    if (now < roscaCollectionTime || forepersonSurplusCollected) {
        throw;
    }

    forepersonSurplusCollected = true;
    uint256 amountToCollect = this.balance - totalFees;
    if (!foreperson.send(amountToCollect)) {   
      
      
      forepersonSurplusCollected = false;
      return false;
    } else {
      LogForepersonSurplusWithdrawal(amountToCollect);
    }
  }

  
  function endOfROSCARetrieveFees() onlyFromFeeAddress roscaEnded external returns (bool) {
    uint256 tempTotalFees = totalFees;  
    totalFees = 0;
    if (!FEE_ADDRESS.send(tempTotalFees)) {   
      
      
      totalFees = tempTotalFees;
      return false;
    } else {
      
      LogFundsWithdrawal(FEE_ADDRESS, totalFees);
    }
  }

  
  function enableEscapeHatch() onlyFromEscapeHatchEnabler external {
    escapeHatchEnabled = true;
    LogEscapeHatchEnabled();
  }

  
  function activateEscapeHatch() onlyFromForeperson external {
    if (!escapeHatchEnabled) {
      throw;
    }
    escapeHatchActive = true;
    LogEscapeHatchActivated();
  }

  
  function emergencyWithdrawal() onlyFromForeperson onlyIfEscapeHatchActive {
    LogEmergencyWithdrawalPerformed(this.balance);
    
    selfdestruct(foreperson);
  }
}
