// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {MyGovernor} from "../src/MyGovenor.sol";
import {Box} from "../src/Box.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {GovToken} from "../src/GovToken.sol";

contract MyGovernorTest is Test{
    MyGovernor myGovernor;
    Box box;
    TimeLock timeLock;
    GovToken govToken;

    address[] proposers;
    address[] executors;
    uint256[] s_values;
    bytes[] calldatas;
    address[] targets;

    address public USER = makeAddr("user");
    uint256 public INITIAL_SUPPLY = 100 ether;
    uint256 public constant MIN_DELAY = 3600;
    uint256 public constant VOTING_DELAY = 7200; // How many blocks till a vote is active
    uint256 public constant VOTIN_PERIOD = 50400;


    function setUp() public{
        govToken = new GovToken();
        govToken.mint(USER, INITIAL_SUPPLY);

        vm.startPrank(USER);
        govToken.delegate(USER);

        timeLock = new TimeLock(MIN_DELAY, proposers, executors);
        myGovernor = new MyGovernor(govToken, timeLock);
        
        bytes32 proposerRole = timeLock.PROPOSER_ROLE();
        bytes32 executorRole = timeLock.EXECUTOR_ROLE();
        bytes32 adminRole = timeLock.TIMELOCK_ADMIN_ROLE();

        timeLock.grantRole(proposerRole, address(myGovernor));
        timeLock.grantRole(executorRole, address(0));
        timeLock.revokeRole(adminRole, USER);
        vm.stopPrank();

        box = new Box();
        box.transferOwnership(address(timeLock));
    }

    function testCantUpdateBoxWithoutGovernance() public{
        vm.expectRevert();
        box.store(1);
    }

    function testGovernanceUpdatesBox() public {
        uint256 valueToStore = 888;

        string memory description = "store 1 in Box";
        bytes memory encodedFunctionCall = abi.encodeWithSignature("store(uint256)", valueToStore);
        s_values.push(0);

        calldatas.push(encodedFunctionCall);
        targets.push(address(box));

        // Propose to the DAO
        uint256 proposalId = myGovernor.propose(targets, s_values, calldatas, description);
        console.log("Proposal State: ", uint256(myGovernor.state(proposalId))); 

        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);
        console.log("Proposal State: ", uint256(myGovernor.state(proposalId))); 

        // Vote
        string memory reason = "Couse we are strong";
        uint8 voteFor = 1;
        vm.prank(USER);
        myGovernor.castVoteWithReason(proposalId, voteFor, reason);

        vm.warp(block.timestamp + VOTIN_PERIOD + 1);
        vm.roll(block.number + VOTIN_PERIOD + 1);

        // Queue the TX
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        myGovernor.queue(targets, s_values, calldatas, descriptionHash);
        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);
        // Execute
        myGovernor.execute(targets, s_values, calldatas, descriptionHash);
    
        assertEq(box.getNumber(), valueToStore);
    }
}