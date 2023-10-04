#! /usr/bin/env node
require("dotenv").config();
const ethers = require("ethers");
const yargs = require("yargs");
const fs = require("fs");

const SEPOLIA_RPC_WEB_SOCKET = process.env.SEPOLIA_WEB_SOCKET;
const MUMBAI_RPC_WEB_SOCKET = process.env.MUMBAI_WEB_SOCKET;
const BRIDGE_ADDRESS = process.env.BRIDGE_ADDRESS;
const USER_KEY = process.env.REGULAR_USER;

const abiPath = "../hardhatProject/artifacts/contracts";
const bridgeAbi = JSON.parse(
  fs.readFileSync(abiPath + "/LMTBridge.sol/LMTBridge.json")
).abi;
const wERC20Abi = JSON.parse(
  fs.readFileSync(abiPath + "/wERC20.sol/wERC20.json")
).abi;

const sourceProvider = new ethers.WebSocketProvider(SEPOLIA_RPC_WEB_SOCKET);
const destinationProvider = new ethers.WebSocketProvider(MUMBAI_RPC_WEB_SOCKET);

const bridgeContract = new ethers.Contract(
  BRIDGE_ADDRESS,
  bridgeAbi,
  sourceProvider
);

let sourceSigner = new ethers.Wallet(USER_KEY, sourceProvider);
let destinationSigner = new ethers.Wallet(USER_KEY, destinationProvider);

const options = yargs
  .usage("Select action to perform on the bridge.")
  .command(
    "lock <address> <amount>",
    "Lock amount of funds on source chain.",
    (yargs) => {
      yargs
        .positional("amount", {
          describe: "The amount to lock",
          type: "string",
        })
        .positional("address", {
          describe: "The address of ERC20 token ",
          type: "string",
        });
    }
  )
  .command(
    "claim <address> <amount> <r> <s> <v>",
    "Claim amount of funds on destination chain.",
    (yargs) => {
      yargs.positional("address", {
        describe: "Token address on destination chain",
        type: "string",
      });
      yargs.positional("amount", {
        describe: "The amount to claim",
        type: "string",
      });
      yargs.positional("r", {
        describe: "R value of the signature",
        type: "string",
      });
      yargs.positional("s", {
        describe: "S value of the signature",
        type: "string",
      });
      yargs.positional("v", {
        describe: "V value of the signature",
        type: "string",
      });
    }
  )
  .command(
    "burn <address> <amount>",
    "Burn funds on destination chain.",
    (yargs) => {
      yargs.positional("address", {
        describe: "Address of the token on destination chain",
        type: "string",
      });
      yargs.positional("amount", {
        describe: "The amount to burn",
        type: "string",
      });
    }
  )
  .command(
    "release <address> <amount> <r> <s> <v>",
    "Release locked funds on source chain.",
    (yargs) => {
      yargs.positional("address", {
        describe: "Address of the token on source chain",
        type: "string",
      });
      yargs.positional("amount", {
        describe: "The amount to release",
        type: "string",
      });
      yargs.positional("r", {
        describe: "R value of the signature",
        type: "string",
      });
      yargs.positional("s", {
        describe: "S value of the signature",
        type: "string",
      });
      yargs.positional("v", {
        describe: "V value of the signature",
        type: "string",
      });
    }
  )
  .help().argv;

// Get the command and amount from the parsed options
const command = options._[0];
main();
async function main() {
  let token = options.address;
  let amount = options.amount;
  let wERC20;
  let result;
  let r = options.r;
  let s = options.s;
  let v = options.v;
  // Perform actions based on the selected command
  switch (command) {
    case "lock":
      console.log(`Locking ${amount} of ${token}.`);
      const result = await bridgeContract
        .connect(sourceSigner)
        .lockTokens(token, amount);

      console.log(`Result ${result}.`);
      // Add your logic here
      break;
    case "claim":
      wERC20 = new ethers.Contract(token, wERC20Abi, destinationProvider);

      console.log(`${destinationSigner.address} address of claimer`);
      result = await wERC20
        .connect(destinationSigner)
        .mintWithSignature(destinationSigner.address, amount, v, r, s);

      console.log(`Result ${result}.`);
      console.log(`Claiming ${amount} on destination chain.`);
      // Add your logic here
      break;
    case "burn":
      wERC20 = new ethers.Contract(token, wERC20Abi, destinationProvider);
      result = await wERC20.connect(destinationProvider).burn(amount);
      // Perform burn action with the specified amount
      console.log(`Burning ${amount} on destination chain.`);
      // Add your logic here
      break;
    case "release":
      result = await bridgeContract
        .connect(sourceSigner)
        .unlockTokensWithSignature(token, amount, v, r, s);

      console.log(`Releasing ${amount} on source chain.`);
      // Add your logic here
      break;
    default:
      // Handle invalid or unsupported commands
      console.error("Invalid command. Use one of: lock, claim, burn, release.");
      break;
  }
}
