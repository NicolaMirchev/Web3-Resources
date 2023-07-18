// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Fallout} from "../src/Fallout.sol";
import {DeployForceAndAtack} from "../script/DeployForceAttack.s.sol";
import {Force, Attacker} from "../src/Force.sol";


contract ForceTest is Test{
    address public  USER = makeAddr("USER");
    uint256 constant ETH = 1 ether;
    Force force;
    Attacker attack;

    function setUp() public{
       DeployForceAndAtack deployer = new DeployForceAndAtack();
       (force, attack) = deployer.run();
    }

    function testTransferEtherAttack() public{
        hoax(USER, ETH);
        attack.deposit{value: ETH}();
        assertEq(address(force).balance, 0);

        attack.destructContractAndSendEthToForce();
        assertEq(address(force).balance, ETH);
    }
}