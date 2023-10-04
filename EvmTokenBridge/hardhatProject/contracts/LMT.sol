// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @author  . Nikola Mirchev
 * @title   . Lime Token
 * @dev     . The owner of the contract is not neccesarry the relyer. Minting logic could vary, depending of the economical peg system.
 * @notice  .
 */

contract LMT is ERC20, Ownable{
    constructor() ERC20("Lime Token", "LMT") Ownable() {   
        // Default is okay.
    }

    /**
     * @notice  . Admin decidedes to mint some tokens on some addresses.
     * @dev     . This function is only callable by the owner and is not good mechanism for ERCs, but this is exercise.
     * @param   to  . The address of the user, who will receive the minted tokens.
     * @param   amount  . The amount of LMT to be minted.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}