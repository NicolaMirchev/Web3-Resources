// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MagicNum {
    address public solver;

    constructor() {}

    function setSolver(address _solver) public {
        solver = _solver;
    }

    /*
    ____________/\\\_______/\\\\\\\\\_____        
     __________/\\\\\_____/\\\///////\\\___       
      ________/\\\/\\\____\///______\//\\\__      
       ______/\\\/\/\\\______________/\\\/___     
        ____/\\\/__\/\\\___________/\\\//_____    
         __/\\\\\\\\\\\\\\\\_____/\\\//________   
          _\///////////\\\//____/\\\/___________  
           ___________\/\\\_____/\\\\\\\\\\\\\\\_ 
            ___________\///_____\///////////////__
  */
}

// Opcodes to return 42.
// 1. Push value of 42 to the top of the stack -> 602a
// 2. Add memory location to the top of the stack-> 6050 (50 is the memory allocation in which we are going to store 42)
// 3. Save the word on the memory location -> 52 (save location -> topest element, value -> second element)
// 4. Push the size of the result to the top of the stack -> 6020 (32 bytes)
// 5. Push the slot on which is the result being -> 6052
// 6. Return the result -> f3
// The whole bytecode is -> 602a60505260206050f3

// Contract init opcodes:
// 1. Push size of the runtime code (10 bytes) -> 600a
// 2. Push the location of the runtime code in the stac (we don't know it) -> 60--
// 3. Push the desired destination in memory to the stack -> 6000
// 4. Use copycode opcode to copy code of size S from destination X to destination Y in memory -> 39
// 5. Push size of runtime code to stack -> 600a
// 6. Push desctination of the bytecode from memory -> 6000
// 7. Return the result -> f3
// The whole init bytecode is -> 600a60--600039600a6000f3, which is 12 bytes, which means that runtime code starts at 0c (13)
// => 600a600c600039600a6000f3
// To obtain the final code we should concat the init bytecode with the runtime.
// => 600a600c600039600a6000f3602a60505260206050f3

contract Solver {
    function whatIsTheMeaningOfLife() external returns (uint256) {
        return 42;
    }
}
