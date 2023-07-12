// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {UUPSUpgradeable}  from"../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable}  from"../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {Initializable}  from"../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

contract BoxV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable{
    uint256 internal number;

    constructor(){
        _disableInitializers();
    }

    function initialize() public initializer{
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function getNumber() external view  returns (uint256) {
        return number;
    }

    function version() external pure returns (uint256){
        return 1;
    }

    function _authorizeUpgrade(address newImplementation) internal override {
    } 
}