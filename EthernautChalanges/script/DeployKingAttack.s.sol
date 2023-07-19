// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {Attacker} from "../src/King.sol";

contract DeployKingAttack is Script {
    address public constant TOKEN_CONTRACT_ADDRESS =
        0xfc448D74b81282C565630DBb130Be991Bf6E0A1B;

    function run() external {
        vm.startBroadcast();
        Attacker attacker = new Attacker(
            0xfc448D74b81282C565630DBb130Be991Bf6E0A1B
        );
        console.log(address(this));
        attacker.attack{value: 0.002 ether}();
        vm.stopBroadcast();
    }
}
