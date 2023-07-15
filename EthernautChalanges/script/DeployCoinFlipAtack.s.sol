// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {Attacker} from "../src/CoinFlip.sol";

contract DeplyFlipCoin is Script{
    address public constant FLIP_COIN_ADDRESS = 0xb7D0e195732ab970cD3E9aECB0eB6fA86bF49371;
    Attacker attacker;

    function run() external {
        vm.startBroadcast();
        attacker= new Attacker(FLIP_COIN_ADDRESS);
        vm.stopBroadcast();
        attacker.attack();
        console.log(address(attacker));
    }
}