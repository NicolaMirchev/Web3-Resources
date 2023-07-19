// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {Attacker, Force} from "../src/Force.sol";

contract DeployForceAndAtack is Script {
    Force force;
    Attacker attacker;

    function run() external returns (Force, Attacker) {
        vm.startBroadcast();
        force = Force(0x5C5Be5BEC9e36fda8C5F80049D3C223aa2e2E0e2);
        attacker = new Attacker(address(force));
        vm.stopBroadcast();

        return (force, attacker);
    }
}
