// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;


contract Bank{
address public owner; 
mapping (address => uint) credit;

constructor(){
    owner = msg.sender;
}

function deposit()public payable{
    credit[msg.sender] += msg.value;
}

function withdraw(uint amount) public{
bool success;
bytes memory data;
if (credit[msg.sender]>= amount) {
    credit[msg.sender] = credit[msg.sender] - amount;
    (success, data) = msg.sender.call{value:amount}("");
    require(success);
  }
 }
}