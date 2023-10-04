import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { WLMT } from "../../typechain-types/contracts/WLMT";
import { expect } from "chai";
import { ethers } from "hardhat";
import { prepareSignature } from "./Util";

describe("wLMT", function () {
  let wLMTToken: WLMT;
  const domainName = "Wrapped LMT";
  const domainVersion = "1";
  const hardhatChainId = 31337;
  const valueToBeMinted = 100;

  async function deploywLMTFixture() {
    const [owner, otherAccount] = await ethers.getSigners();

    const wLMTFactory = await ethers.getContractFactory("wERC20");
    const wLMT = await wLMTFactory.deploy("LMT");
    wLMTToken = wLMT as WLMT;

    return { wLMT, owner, otherAccount };
  }

  async function mintTokensFixture() {
    const { wLMT, owner, otherAccount } = await deploywLMTFixture();

    const { r, s, v } = await prepareSignature(
      domainName,
      domainVersion,
      hardhatChainId,
      await wLMT.getAddress(),
      await owner.getAddress(),
      await otherAccount.getAddress(),
      valueToBeMinted,
      await wLMTToken.nonces(await otherAccount.getAddress())
    );

    await wLMTToken.mintWithSignature(
      await otherAccount.getAddress(),
      valueToBeMinted,
      v,
      r,
      s
    );

    return { wLMT, owner, otherAccount, r, s, v };
  }

  describe("Actions", function () {
    context("Deployment", function () {
      it("Should set the right owner", async function () {
        const { wLMT, owner, otherAccount } = await deploywLMTFixture();

        expect(await (wLMT as any).owner()).to.equal(owner.address);
      });
    });

    context("Minting", function () {
      it("Should be possible to mint tokens to an address using signature from owner.", async function () {
        const { wLMT, owner, otherAccount } = await deploywLMTFixture();

        const { r, s, v } = await prepareSignature(
          domainName,
          domainVersion,
          hardhatChainId,
          await wLMT.getAddress(),
          await owner.getAddress(),
          await otherAccount.getAddress(),
          valueToBeMinted,
          await wLMTToken.nonces(await otherAccount.getAddress())
        );

        expect(
          await wLMTToken
            .connect(otherAccount)
            .mintWithSignature(
              await otherAccount.getAddress(),
              valueToBeMinted,
              v,
              r,
              s
            )
        )
          .to.emit(wLMTToken, "TokenClaimed")
          .withArgs(otherAccount.address, 1000);
      });
    });

    context("Burning", function () {
      it("Should be possible to burn tokens for user, who has previously minted.", async function () {
        const { wLMT, owner, otherAccount } = await mintTokensFixture();
        // Burn toknes

        expect(await wLMTToken.connect(otherAccount).burn(valueToBeMinted))
          .to.emit(wLMTToken, "TokenBurned")
          .withArgs(otherAccount.address, valueToBeMinted);
      });
    });
  });
  describe("Reverts", function () {
    context("Minting", function () {
      it("Should revert if signature is from wrong signer", async function () {
        const { wLMT, owner, otherAccount } = await deploywLMTFixture();

        const { r, s, v } = await prepareSignature(
          domainName,
          domainVersion,
          hardhatChainId,
          await wLMT.getAddress(),
          await otherAccount.getAddress(),
          await otherAccount.getAddress(),
          valueToBeMinted,
          await wLMTToken.nonces(await otherAccount.getAddress())
        );

        await expect(
          wLMTToken
            .connect(otherAccount)
            .mintWithSignature(
              await otherAccount.getAddress(),
              valueToBeMinted,
              v,
              r,
              s
            )
        ).to.be.revertedWith("wToken Mint: Invalid signature");
      });
      it("Should revert if signature same signature is used two times", async function () {
        const { wLMT, owner, otherAccount, r, s, v } =
          await mintTokensFixture();

        await expect(
          wLMTToken
            .connect(otherAccount)
            .mintWithSignature(
              await otherAccount.getAddress(),
              valueToBeMinted,
              v,
              r,
              s
            )
        ).to.be.revertedWith("wToken Mint: Invalid signature");
      });
    });
    context("Burning", function () {
      it("Should revert if user tries to burn more tokens than he has", async function () {
        const { wLMT, owner, otherAccount } = await mintTokensFixture();

        await expect(
          wLMTToken.connect(otherAccount).burn(valueToBeMinted + 1)
        ).to.be.revertedWith("ERC20: burn amount exceeds balance");
      });
    });
  });
});
