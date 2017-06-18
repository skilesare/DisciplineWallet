pragma solidity ^0.4.11;

contract DisciplineWallet {

  /**
  * @dev term is the number of months that a wallet will pay out
  */
  uint16 public term;


  /**
  * @dev currentTerm tracks the number of withdraws that have occured
  */
  uint16 public currentTerm;

  /**
  * @dev contractStart stores the timestamp(number of seconds since 1/1/1970) that the contract was created
  */
  uint public contractStart;

  /**
  * @dev payout is the number of wei(smallest unit of ETH) to pay out
  */
  uint public payout;


  /**
  * @dev bActive is tracks if the wallet is open for business or not
  */
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

  /**
   * @dev constructor
   * @param termLength number of months that the contract will be active
   * @param number of wei to pay out
   */
  function DisciplineWallet(uint16 termLength, uint weiOutputPerPeriod) {

    if(termLength < 1) throw; //term cant be 0
    if(weiOutputPerPeriod < 1) throw; //we cant pay out 0

    //the owner will start as the address creating the contract
    owner = msg.sender;

    //set the term
    term = termLength;

    //record the time of the start contract
    contractStart = now;

    //start with the current term as 1
    currentTerm = 1;

    //set the payout per period
    payout = weiOutputPerPeriod;
  }


  /**
   * @dev calculates the length of a month
   */
  function Period() constant returns (uint32 lengthOfMonth){
    //put this in a constant function so that we don't have to use storage
    //execution takes 302 gas which means calculation is more efficent in any contract under 66 months.
    //not sure about deployment costs
    //the period is about 30.66 days so that leap year is taken into account every 4 years.
    return (1 years / 12) + (1 days / 4);
  }

  /**
   * @dev tells us what date we can call the withdraw function
   */
  function NextWithdraw() constant returns(uint secondsAfter1970){
    return contractStart + (Period() * currentTerm);
  }

  /**
   * @dev the fallback function will make a deposit
   */
  function () payable{
    Deposit();
  }

  /**
   * @dev Put ETH into the contract, also called by the fallback function
   */
  function Deposit() payable {
    //don't accept ether if the term is over
    if(currentTerm > term) throw;
    if(bActive == false){
      //first time we get ether, turn on the contract
      bActive = true;
    }
  }

  /**
   * @dev Withdraw will send the payout to the owner if enough time has passed
   */
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


  /**
   * @dev once all terms have expired you can move any remaining ETH to another account
   * @param targetAddress The address to transfer remaining ETH to.
   */
  function WithdrawAll(address targetAddress) onlyOwner returns(bool ok){
    if (targetAddress == 0x0) throw; //dont accidentally burn ether
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

  /**
   * @dev Allows the owner to send tokens elsewhere that were accidentally sent to this account
   * @param Token The address of the ERC20 token
   * @param _to The address the tokens should end up at
   * @param _value The amount of tokens
   */
  function safetyTransferToken(address Token, address _to, uint _value) onlyOwner returns (bool ok){
    bytes4 sig = bytes4(sha3("transfer(address,uint256)"));
    return Token.call(sig, _to, _value);
  }

}
