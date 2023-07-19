// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
In the current example we have a contract, which defines multiple state variables, which are less than a storage slot capacity (32 bytes)
In this case solidity compiler fit (where is possible) variables in a single storage slot.
We have to understand which is the slot of the _key element. For defined arrays the values are stored sequentially in the 
storage. i.e we should request the element which points to the _key in the storage.
Slots:
[0] -> bool locked
[1] -> uint256 ID
[2] -> uint8 flattening, uint8 denomination, uint16 awkwardness
[3] -> bytes32[0] data[0]
[4] -> bytes32[1] data[1] 
[5] -> bytes32[2] data[2] -> The key is the first 16 bytes from this slot.
*/

contract Privacy {
    bool public locked = true;
    uint256 public ID = block.timestamp;
    uint8 private flattening = 10;
    uint8 private denomination = 255;
    uint16 private awkwardness = uint16(block.timestamp);
    bytes32[3] private data;

    constructor(bytes32[3] memory _data) {
        data = _data;
    }

    function unlock(bytes16 _key) public {
        require(_key == bytes16(data[2]));
        locked = false;
    }
}
