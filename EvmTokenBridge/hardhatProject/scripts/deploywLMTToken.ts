import { ethers } from "hardhat";
import { token } from "../typechain-types/@openzeppelin/contracts";

export async function main() {
  const contract = await ethers.deployContract("wERC20", ["LMT"]);
  await contract.waitForDeployment();

  console.log(`Token has been deployed on ${await contract.getAddress()}}`);
}

main().catch((error) => {
  console.log(error);
  process.exitCode = 1;
});
