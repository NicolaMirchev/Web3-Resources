import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const TEST_DEPLOYER_PRIVATE_KEY =
  "eb707b26189ecfe7fbdab4c931ea26ebee6c71540702884ec077cd4d429741cb";
const TEST_USER_PRIVATE_KEY =
  "024cfeda12af56c023f3a486636d2f84b4f7552711ff64f9d8b172833d8684c3";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    sepolia: {
      url: "https://sepolia.infura.io/v3/76c20b466e344a70af7aaff17ef028c3",
      chainId: 11155111,
      accounts: [TEST_DEPLOYER_PRIVATE_KEY, TEST_USER_PRIVATE_KEY],
    },
    mumbai: {
      url: "https://polygon-mumbai.g.alchemy.com/v2/3d8R92I2uP1NH--GPXXyPI9I-3iFFrbs",
      chainId: 80001,
      accounts: [TEST_DEPLOYER_PRIVATE_KEY, TEST_USER_PRIVATE_KEY],
    },
  },
};

export default config;
