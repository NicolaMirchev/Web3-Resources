// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
 
import {SimpleStorage} from "./SimpleStorage.sol";

contract StorageFactory{

    SimpleStorage[] public simpleStorages;
    address[] public listOfSimpleStorageAddresses;

    function createSimpleStorageContract() public {
        simpleStorages.push(new SimpleStorage());
    }

    function sfStore(uint256 _simpleStorageIndex, uint256 _newSimpleStorageNumber) public {
        // Address
        // ABI - Application Binary Interface
        SimpleStorage myStorage = simpleStorages[_simpleStorageIndex];
        myStorage.store(_newSimpleStorageNumber);
    }

    function sfGet(uint256 _storageIndex) public view returns(uint256){
         return simpleStorages[_storageIndex].retrieve();
    }

}