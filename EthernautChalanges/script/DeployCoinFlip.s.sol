// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {CoinFlip} from "../src/CoinFlip.sol";

contract DeplyFlipCoin is Script{
    function run() external {
        vm.startBroadcast();
        new CoinFlip();
        vm.stopBroadcast();
    }
}