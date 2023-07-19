// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {AttackBuilding, Elevator} from "../src/Building.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployBuildingAttack is Script {
    function run() external returns (AttackBuilding) {
        HelperConfig helperConfig = new HelperConfig();
        address elevatorAddress = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        AttackBuilding building = new AttackBuilding(elevatorAddress);
        vm.stopBroadcast();
        return building;
    }
}
