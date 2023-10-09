//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ExampleExternalContract.sol";

contract Staker {
  ExampleExternalContract public exampleExternalContract;

  // mappings
  mapping(address => uint256) public balances; 
  mapping(address => uint256) public depositTimestamps;

  // variables
  uint256 public constant rewardRatePerSecond = 0.1 ether; 
  uint256 public withdrawalDeadline = block.timestamp + 120 seconds; 
  uint256 public claimDeadline = block.timestamp + 240 seconds; 
  uint256 public currentBlock = 0;

  // events
  event Stake(address indexed sender, uint256 amount); 
  event Received(address, uint); 
  event Execute(address indexed sender, uint256 amount);

  constructor(address exampleExternalContractAddress) public {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // modifiers
  modifier withdrawalDeadlineReached( bool requireReached ) {
    uint256 timeRemaining = withdrawalTimeLeft();
    if( requireReached ) {
      require(timeRemaining == 0, "Withdrawal period is not reached yet");
    } else {
      require(timeRemaining > 0, "Withdrawal period has been reached");
    }
    _;
  }

  modifier claimDeadlineReached( bool requireReached ) {
    uint256 timeRemaining = claimPeriodLeft();
    if( requireReached ) {
      require(timeRemaining == 0, "Claim deadline is not reached yet");
    } else {
      require(timeRemaining > 0, "Claim deadline has been reached");
    }
    _;
  }
  
  modifier notCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, "Stake already completed!");
    _;
  }

  // functions
  function withdrawalTimeLeft() public view returns (uint256 timeLeft) {
    if( block.timestamp >= withdrawalDeadline) {
      return (0);
    } else {
      return (withdrawalDeadline - block.timestamp);
    }
  }

  function claimPeriodLeft() public view returns (uint256 timeLeft) {
    if( block.timestamp >= claimDeadline) {
      return (0);
    } else {
      return (claimDeadline - block.timestamp);
    }
  }

  // Stake function for a user to stake ETH in our contract
  function stake() public payable withdrawalDeadlineReached(false) claimDeadlineReached(false) {
    balances[msg.sender] = balances[msg.sender] + msg.value;
    depositTimestamps[msg.sender] = block.timestamp;
    emit Stake(msg.sender, msg.value);
  }

  /*
  Withdraw function for a user to remove their staked ETH inclusive
  of both the principle balance and any accrued interest
  */
  function withdraw() public withdrawalDeadlineReached(true) claimDeadlineReached(false) notCompleted{
    require(balances[msg.sender] > 0, "You have no balance to withdraw!");
    uint256 individualBalance = balances[msg.sender];
    uint256 indBalanceRewards = individualBalance + ((block.timestamp-depositTimestamps[msg.sender]) * rewardRatePerSecond);
    balances[msg.sender] = 0;

    // Transfer all ETH via call! (not transfer) cc: https://solidity-by-example.org/sending-ether
    (bool sent, ) = msg.sender.call{value: indBalanceRewards}("");
    require(sent, "RIP; withdrawal failed :( ");
  }

  /*
  Allows any user to repatriate "unproductive" funds that are left in the staking contract
  past the defined withdrawal period
  */
  function execute() public claimDeadlineReached(true) notCompleted {
    uint256 contractBalance = address(this).balance;
    exampleExternalContract.complete{value: contractBalance}();
  }

  // enable receiving ETH
  receive() external payable {
    emit Received(msg.sender, msg.value);
  }
}
