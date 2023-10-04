import { LMT } from "../../typechain-types/contracts/LMT";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("LMT", function () {
  let LMTToken: LMT;
  const amountToMint = 100;

  async function deployLMTFixture() {
    const [owner, otherAccount] = await ethers.getSigners();

    const LMTFactory = await ethers.getContractFactory("LMT");
    const LMT = await LMTFactory.deploy();
    LMTToken = LMT as LMT;

    return { LMT, owner, otherAccount };
  }

  describe("Actions", function () {
    it("Should deploy LMT with correct owner", async function () {
      const { LMT, owner } = await deployLMTFixture();
      expect(await LMT.owner()).to.equal(owner.address);
    });

    it("Should mint tokens by owner", async function () {
      const { LMT, owner, otherAccount } = await deployLMTFixture();
      await LMT.mint(otherAccount, amountToMint);
      expect(await LMT.balanceOf(otherAccount)).to.equal(amountToMint);
    });
  });

  describe("Reverts", function () {
    it("Should revert if not owner tries to mint", async function () {
      const { LMT, otherAccount } = await deployLMTFixture();
      await expect(
        LMT.connect(otherAccount).mint(otherAccount.address, amountToMint)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });
});
