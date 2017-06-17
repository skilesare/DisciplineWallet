pragma solidity ^0.4.11;



contract DisciplineWallet {
  uint16 public term;
  uint16 public currentTerm;
  uint public contractStart;
  uint public payout;
  bool public bActive;
  address public owner;

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }

  function DisciplineWallet(uint16 termLength, uint weiOutputPerPeriod) {

    if(termLength < 1) throw;
    if(weiOutputPerPeriod < 1) throw;

    //the owner will start as the address creating the contract
    owner = msg.sender;


    term = termLength;

    //record the time of the start contract
    contractStart = now;

    //start with the current term as 1
    currentTerm = 1;

    //set the payout per period
    payout = weiOutputPerPeriod;


  }


  //put this in a constant function so that we don't have to use storage
  //execution takes 302 gas which means calculation is more efficent in any contract under 66 months.
  //not sure about deployment costs
  function Period() constant returns (uint32 lengthOfMonth){
    //the period is about 30.66 days so that leap year is taken into account every 4 years.
    return (1 years / 12) + (1 days / 4);
  }

  //nextWithdrawl tells us what date we can call the withdraw function and explect it to
  //send the money back to us.
  function NextWithdraw() constant returns(uint secondsAfter1970){
    return contractStart + (Period() * currentTerm);
  }

  function () payable{
    Deposit();
  }

  function Deposit() payable {
    //don't accept ether if the term is over
    if(currentTerm > term) throw;
    if(bActive == false){
      //first time we get ether, turn on the contract
      bActive = true;
    }
  }

  function Withdraw() onlyOwner returns(bool ok){

    if(currentTerm <= term && now > NextWithdraw()){

      //payout may not be more than balance / term or the account has been underfunded
      //if it is then use the lower calculatio
      if(payout < (this.balance / (term - currentTerm + 1))){
        owner.transfer(payout);
      }
      else{
        owner.transfer(this.balance / term);
      }

      currentTerm = currentTerm + 1;

      if (currentTerm > term){
        bActive = false;
      }

      return true;
    } else{
      throw;
    }

  }

  function WithdrawAll(address targetAddress) onlyOwner returns(bool ok){
    if (targetAddress == 0x0) throw;
    if(currentTerm > term && this.balance > 0){
      targetAddress.transfer(this.balance);
      bActive = false;
      return true;
    } else {
      throw;
    }

  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

  function safetyTransferToken(address Token, address _to, uint _value) onlyOwner returns (bool ok){
    bytes4 sig = bytes4(sha3("transfer(address,uint256)"));
    return Token.call(sig, _to, _value);
  }

}
