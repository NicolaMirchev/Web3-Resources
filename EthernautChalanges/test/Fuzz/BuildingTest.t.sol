// SPDX-License-Identifier: MIT
pragma solidity ^0.8.00;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {AttackBuilding} from "../../src/Building.sol";
import {DeployBuildingAttack} from "../../script/DeployBuildingAttack.s.sol";
import {Handler} from "./Handler.t.sol";

// Invariant of the building is that every time we go to a floor, it will be the last floor.
contract ElevatorAttackTest is StdInvariant, Test {
    AttackBuilding public building;
    Handler handler;

    function setUp() external {
        DeployBuildingAttack deployBuildingAttack = new DeployBuildingAttack();
        building = deployBuildingAttack.run();
        handler = new Handler(address(building));

        targetContract(address(handler));
    }

    function invariant_goToFloorIsAlwaysLastFloor() public {
        assertTrue(building.elevator().top());
    }
}
