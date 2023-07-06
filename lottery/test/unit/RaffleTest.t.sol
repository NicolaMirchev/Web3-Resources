// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";


contract RaffleTest is Test{
    /**Events */
    event EnteredRaffle(address indexed player);

    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee ;
    uint256 interval;
    address vrfCordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    modifier raffleSetUpkeep {
        vm.prank(PLAYER);   
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function setUp() external{
        DeployRaffle deployer = new DeployRaffle();

        (raffle, helperConfig) = deployer.run();

        (
        entranceFee,
        interval,
        vrfCordinator,
        gasLane,
        subscriptionId,
        callbackGasLimit, 
        link,) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testRaffleInitializesInOOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /////////////////////////// Test enter raffle ////////////////////////////

   function testraffleRecordsPlayersWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee + 1}();
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

     function testEnterRaffleWithNoEnoughtMoney() public {
        address fake = makeAddr("fake");
        vm.prank(fake);
        vm.expectRevert(Raffle.Raffle__NotEnoughtEthSent.selector);
        raffle.enterRaffle();
    }

    function testEmitsEventOnEntrance() public{
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

      function testCantEnterWhenStateIsCalculating() public{
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RafleIsNotOpened.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        // vm.warp // vm.roll
    }

    ///////////// ChekUpKeep /////////////
    function testCheckUpKeepReturnsFalseIfItHasNoBalance() public{
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded == false);
    }

    function testCheckUpKeepReturnFalseIfRaffleNotOpen() public{
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
         assert(upkeepNeeded == false);
    }
    ////////////// performUpkeep////
    
    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public{
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public{
        uint256 currentBalance = 0;
        uint256 players = 0;
        uint256 raffleState = 0;

        vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance, players, raffleState));
        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStatesAndEmmitRequestId() public raffleSetUpkeep{
        vm.recordLogs();
        raffle.performUpkeep(""); // emit the requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        Raffle.RaffleState rState = raffle.getRaffleState();

        assert(uint256(requestId) > 0);
        assert(uint256(rState) == 1);
    }

    ////////// fulfillRandomWords ///////////////
    function testFullfillRadnomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId) public {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCordinator).fulfillRandomWords(randomRequestId, address(raffle));
    }

    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() public raffleSetUpkeep{
        uint256 additionalEntrants = 5;
        uint256 startingIndex = 1;

        for(uint256 i = startingIndex; i < startingIndex + additionalEntrants; i++){
            address player = address(uint160(i));
            hoax(player, STARTING_USER_BALANCE);
            raffle.enterRaffle{value : entranceFee}();
        }

        vm.recordLogs();
        raffle.performUpkeep(""); // emit the requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        uint256 prevTimeStamp = raffle.getLastTimeStamp();

        uint256 prize = entranceFee * additionalEntrants;

        VRFCoordinatorV2Mock(vrfCordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        assert(uint256(raffle.getRaffleState()) == 0);
        assert(raffle.getRecentWinner() != address(0));
        assert(raffle.getLengthOfPlayers() == 0);
        assert(raffle.getLastTimeStamp() != prevTimeStamp);
        assert(raffle.getRecentWinner().balance == STARTING_USER_BALANCE + prize);


    }
}