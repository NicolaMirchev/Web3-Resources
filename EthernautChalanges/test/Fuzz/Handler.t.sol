// SPDX-License-Identifier: MIT
pragma solidity ^0.8.00;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {AttackBuilding} from "../../src/Building.sol";

contract Handler is Test {
    AttackBuilding public building;

    constructor(address _building) {
        building = AttackBuilding(_building);
    }

    function goToFloor(uint256 _floor) public {
        console.log("We go to ", _floor);
        building.goTo(_floor);
    }
}
