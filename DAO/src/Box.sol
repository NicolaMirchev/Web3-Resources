// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Box is Ownable{
    uint256 private s_number;

    event NumberChanged(uint256 number);


    function store(uint256 _number) public onlyOwner{
        s_number = _number;
        emit NumberChanged(_number);
    }

    function getNumber() public view returns(uint256){
        return s_number;
    }
}