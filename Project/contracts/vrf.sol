// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract VRFv2Consumer is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;

  // Your subscription ID.
  uint64 s_subscriptionId;

  // Rinkeby coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 callbackGasLimit = 100000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 public numWords = 1;
  address public s_owner;
  // map rollers to requestIds
  mapping(uint256 => address) private rollers;
  // map vrf results to rollers
  mapping(address => uint256) private results;

  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
    // createNewSubscription();
    //Create a new subscription when you deploy the contract.
    // COORDINATOR.addConsumer(subscriptionId, address(this));
  }

  function senderAddress() external view returns(address) {
      return msg.sender;
  }

  function contractAddress() public view returns(address) {
      return address(this);
  }

  function owner() public view returns(address) {
      return s_owner;
  }

  function getSubscriptionId() public view onlyOwner returns(uint64) {
      return s_subscriptionId;
  }

  function destroy() public payable onlyOwner {
      //destroy the code
      selfdestruct(payable(s_owner));
  } 
  
  // Assumes the subscription is funded sufficiently.
  function requestRandomWords() external returns (uint256) {
    // Will revert if subscription is not set and funded.
    uint256 requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
    rollers[requestId] = msg.sender;
    results[msg.sender] = 0;
    return requestId;
  }

  
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
    results[rollers[requestId]] = randomWords[0];
  }

  function randomNumber(uint256 requestId) external view returns(uint256) {
    uint256 ans = results[msg.sender];
    require(rollers[requestId] == msg.sender, 'Wrong requestId, please reqest random number first');
    require(ans > 0, 'Random number request still in progress');
    return ans;
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }
}
