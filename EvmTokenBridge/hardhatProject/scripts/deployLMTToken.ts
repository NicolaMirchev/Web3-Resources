import { ethers } from "hardhat";
import { token } from "../typechain-types/@openzeppelin/contracts";

export async function main() {
  const contract = await ethers.deployContract("LMT");
  await contract.waitForDeployment();

  const bridge = await ethers.deployContract("LMTBridge");
  await bridge.waitForDeployment();

  console.log(`Token has been deployed on ${await contract.getAddress()}`);
  console.log(`Bridge has been deployed on ${await bridge.getAddress()}`);
}

main().catch((error) => {
  console.log(error);
  process.exitCode = 1;
});
