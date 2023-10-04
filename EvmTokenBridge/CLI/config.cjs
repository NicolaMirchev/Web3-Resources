require("dotenv").config();
const ethers = require("ethers");
const fs = require("fs");
const db = require("./dbConfig.cjs");

const PROVIDER_KEY = process.env.PROVIDER_KEY;
const SEPOLIA_RPC_WEB_SOCKET = process.env.SEPOLIA_WEB_SOCKET;
const MUMBAI_RPC_WEB_SOCKET = process.env.MUMBAI_WEB_SOCKET;
const BRIDGE_ADDRESS = process.env.BRIDGE_ADDRESS;

// ------ Web3 config ------
const abiPath = "../hardhatProject/artifacts/contracts";
const rawDataBridgeContract = fs.readFileSync(
  abiPath + "/LMTBridge.sol/LMTBridge.json"
);
const bridgeAbi = JSON.parse(rawDataBridgeContract).abi;
const sourceProvider = new ethers.WebSocketProvider(SEPOLIA_RPC_WEB_SOCKET);
const bridgeContract = new ethers.Contract(
  BRIDGE_ADDRESS,
  bridgeAbi,
  sourceProvider
);

const sourceSigner = new ethers.Wallet(PROVIDER_KEY, sourceProvider);

// Destination chain
const rawDatawLMTContract = fs.readFileSync(
  abiPath + "/wERC20.sol/wERC20.json"
);
const wERC20Abi = JSON.parse(rawDatawLMTContract).abi;
const destinationProvider = new ethers.WebSocketProvider(MUMBAI_RPC_WEB_SOCKET);
const destinationSigner = new ethers.Wallet(PROVIDER_KEY, destinationProvider);

const dbValues = {
  bridgedAmount: "bridgedAmount",
  lockedAmount: "lockedAmount",
  releasedAmount: "releasedAmount",
  burnedAmount: "burnedAmount",
  actionSignature: "actionSignature",
  used: "used",
  v: "v",
  r: "r",
  s: "s",
};
const usersRef = db.ref("users");
const sourceLastProccessedBlock = db.ref("sourceLastProccessedBlock");
const destinationlastProccessedBlockRef = db.ref(
  "destinationsLastProccessedBlock"
);

module.exports = {
  BRIDGE_ADDRESS,
  bridgeContract,
  sourceSigner,
  destinationSigner,
  sourceProvider,
  destinationProvider,
  bridgeContract,
  wERC20Abi,
  dbValues,
  sourceLastProccessedBlock,
  destinationlastProccessedBlockRef,
  usersRef,
};
