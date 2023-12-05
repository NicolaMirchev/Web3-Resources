## Custom Reentrancy Checker

Provided code does a basic reentrancy check on provided `.sol` file.
Code is considered vulnerable when there is a function with external call using solidity `call` operation and after that modifying a storage variable.

## How to run it:

1. You should have globally installed `npm`
2. Run in terminal in root directory `npm i`
3. Place your `.sol` file/s in the root directory.
4. Run in terminal `npx ts-node index.ts {YOUR .SOL FILE}`
   4 1. Example: `npx ts-node index.ts Bank.sol`
