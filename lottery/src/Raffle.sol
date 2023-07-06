// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
/**
 * @title A samle Raffle Contract
 * @author Nikola Mirchev
 * @notice  This is for creating a sample raffle
 */
contract Raffle is VRFConsumerBaseV2 {
    error Raffle__NotEnoughtEthSent();
    error Raffle__TransferFailed();
    error Raffle__RafleIsNotOpened();
    error Raffle__UpkeepNotNeeded(uint256 addressBalance, uint256 playersCount, RaffleState RaffleState);

    /**Type Declarations */
    enum  RaffleState {
        OPEN, // 0
        CALCULATING //1
    }

    /**State Variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint256 private s_lastTimeStamp;
    address payable[]  private s_players;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /**Events */
    event EnteredRaffle(address indexed player);
    event PickedWinner(address winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(uint256 entranceFee, uint256 interval, address vrfCordinator, bytes32 gasLane, uint64 subscriptionId, uint32 callbackGasLimit)
    VRFConsumerBaseV2(vrfCordinator)
     {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCordinator = VRFCoordinatorV2Interface(vrfCordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable{
        if(s_raffleState != RaffleState.OPEN) revert Raffle__RafleIsNotOpened();
        if(msg.value < i_entranceFee) revert Raffle__NotEnoughtEthSent();
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    // When the winner should be picked?
    /**
     * @dev This is function that the Chainlink Automation nodes call to see if it's time to perform the upkeep.
     * The following should be true for this to return true:
     * 1. The time interval has passed between raffle runs
     * 2. THe raffle is in the OPEN state
     * 3. The contract has ETH(aka, players)
     * 4. (Implicit) The subscription is funded with LINK
      */
  function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
         bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
         bool isOpen = s_raffleState == RaffleState.OPEN;
         bool hasBalance = address(this).balance > 0;
         bool hasPlayers = s_players.length > 0;
         upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
         return (upkeepNeeded, "0x0");
    }
        // 2. Use the random number to pick a player
    // 3. Be automatically called
    function performUpkeep(bytes calldata /* performData */) public{
        (bool upkeepNeeded, ) = checkUpkeep("");
        if(!upkeepNeeded){
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, s_raffleState);
        }

        s_raffleState = RaffleState.CALCULATING;
        // chek if enough time has passed
        if((block.timestamp - s_lastTimeStamp) < i_interval){
            revert();
        }
           uint256 requestId =  i_vrfCordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    // 1. Get a random number
    }


    // CEI: Checks, Effects, Interactions 
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override{

        address payable winner = s_players[randomWords[0] % s_players.length];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;

        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        (bool success,) = s_recentWinner.call{value: address(this).balance}("");
        if(!success) revert Raffle__TransferFailed();
        emit PickedWinner(winner);
    }
    // 1. Request the RNG
    // 2. Get the random number

    function getEntranceFee() public view returns(uint256){
        return i_entranceFee;
    }

    function getRaffleState() external view returns(RaffleState){
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address){
        return s_players[indexOfPlayer];
    }

    function getRecentWinner() external view returns(address){
        return s_recentWinner;
    }

    function getLengthOfPlayers() external view returns(uint256){
        return s_players.length;
    }

    function getLastTimeStamp() external view returns(uint256){
        return s_lastTimeStamp;
    }
}
