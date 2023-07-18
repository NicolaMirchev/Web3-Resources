// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// To crack this code and take ownership of Delegation contract, we should call Delagation fallback function and in the
// data field, we should include "pwn()" function to be called?

contract Delegate {

  address public owner;

  constructor(address _owner) {
    owner = _owner;
  }

  function pwn() public {
    owner = msg.sender;
  }
}

contract Delegation {

  address public owner;
  Delegate delegate;

  constructor(address _delegateAddress) {
    delegate = Delegate(_delegateAddress);
    owner = msg.sender;
  }

  fallback() external {
    (bool result,) = address(delegate).delegatecall(msg.data);
    if (result) {
      this;
    }
  }
}
