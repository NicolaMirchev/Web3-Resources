// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {Elevator} from "../src/Building.sol";

contract HelperConfig is Script {
    address private constant ELEVATOR_ADDRESS_SEPOLIA =
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    struct NetworkConfig {
        address elevatorAddress;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaChainConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilChainConfig();
        }
    }

    function getSepoliaChainConfig() internal returns (NetworkConfig memory) {
        return NetworkConfig({elevatorAddress: ELEVATOR_ADDRESS_SEPOLIA});
    }

    function getOrCreateAnvilChainConfig()
        internal
        returns (NetworkConfig memory)
    {
        if (activeNetworkConfig.elevatorAddress != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        Elevator elevator = new Elevator();
        vm.stopBroadcast();
        return NetworkConfig({elevatorAddress: address(elevator)});
    }
}
