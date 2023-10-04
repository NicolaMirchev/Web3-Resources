// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title OracleLib
 * @author Nikola Mirchev
 * @notice This library is used to check the Chainlink Oracle for stale data.
 * If a price is stale, the function will revert and the DSCEngine unusable- this is by design
 * We want the DSCEngine to freeze if prices become stale.
 * 
 * So if the Chainlink network explodes and you have a lot of money locked in the protocol...
 */
library  OracleLib {
    error OracleLib__StalePrice();
    uint256 private constant TIMEOUT = 3 hours;

    function staleCheckLatestRoundData(AggregatorV3Interface prifeFeed) public view returns(uint80, int256, uint256,uint256,uint80 ){
              (uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound) = prifeFeed.latestRoundData();

      uint256 secondsSince = block.timestamp - updatedAt;
      if(secondsSince > secondsSince) revert OracleLib__StalePrice();
      return (roundId,
       answer,
       startedAt,
       updatedAt,
       answeredInRound);
    }
    
}