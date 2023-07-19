// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {Privacy} from "../src/Privacy.sol";

contract FindStorageSlotValue is Script {
    address public constant PRIVACY_CONTRACT_ADDRESS =
        0x5faFbeCc3Fc453147E8C4a070fC5b1dC676F5643;

    uint256 public startSlot = 5;

    function run() external {
        vm.startBroadcast();
        bytes16 key = bytes16(
            vm.load(PRIVACY_CONTRACT_ADDRESS, bytes32(startSlot))
        );

        Privacy(PRIVACY_CONTRACT_ADDRESS).unlock(key);
        console.logBytes16(key);
        vm.stopBroadcast();
    }
}
