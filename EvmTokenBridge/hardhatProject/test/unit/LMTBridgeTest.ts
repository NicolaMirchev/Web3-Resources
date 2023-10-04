import { LMT, LMTBridge } from "../../typechain-types/contracts";
import { expect } from "chai";
import { ethers } from "hardhat";
import { prepareSignatureRelease } from "./Util";

describe("LMTBridge", function () {
  let LMTToken: LMT;
  let lmtAddress: string;
  let LMTBridge: LMTBridge;
  const amountOfTokensToLock = 100;
  const domainName = "LMTBridge";
  const domainVersion = "1";
  const hardhatChainId = 31337;

  async function lockTokensFixture() {
    const { LMT, LMTBridge, owner, otherAccount } =
      await deployContractsFixture();
    await LMT.mint(otherAccount.address, amountOfTokensToLock);
    await LMT.connect(otherAccount).approve(
      LMTBridge.getAddress(),
      amountOfTokensToLock
    );
    lmtAddress = await LMT.getAddress();
    await LMTBridge.addDestinationChainToken(lmtAddress, lmtAddress);

    await LMTBridge.connect(otherAccount).lockTokens(
      lmtAddress,
      amountOfTokensToLock
    );

    return { LMT, LMTBridge, owner, otherAccount };
  }

  async function deployContractsFixture() {
    const [owner, otherAccount] = await ethers.getSigners();

    const LMTFactory = await ethers.getContractFactory("LMT");
    const LMT = await LMTFactory.deploy();
    LMTToken = LMT as LMT;

    const LMTBridgeFactory = await ethers.getContractFactory("LMTBridge");
    const Bridge = await LMTBridgeFactory.deploy();
    LMTBridge = Bridge as LMTBridge;

    return { LMT, LMTBridge, owner, otherAccount };
  }

  describe("Actions", function () {
    context("Deployment & Owner interactions", function () {
      it("Should be deployed with correct owner and LMT address", async function () {
        const { LMT, LMTBridge, owner } = await deployContractsFixture();
        expect(await LMTBridge.owner()).to.equal(owner.address);
      });
      it("Should be possible add new tokens only by owner", async function () {
        const { LMT, LMTBridge, owner, otherAccount } =
          await deployContractsFixture();

        const address = await LMT.getAddress();
        await expect(
          LMTBridge.addDestinationChainToken(
            await LMT.getAddress(),
            await LMT.getAddress()
          )
        )
          .to.emit(LMTBridge, "TokenAdded")
          .withArgs(address, address);
      });
    });

    context("User locking funds", function () {
      it("Should lock tokens for the correct user", async function () {
        const { LMT, LMTBridge, owner, otherAccount } =
          await deployContractsFixture();
        await LMT.mint(otherAccount.address, amountOfTokensToLock);
        await LMT.connect(otherAccount).approve(
          LMTBridge.getAddress(),
          amountOfTokensToLock
        );
        lmtAddress = await LMT.getAddress();
        await LMTBridge.addDestinationChainToken(lmtAddress, lmtAddress);

        expect(
          await LMTBridge.connect(otherAccount).lockTokens(
            lmtAddress,
            amountOfTokensToLock
          )
        )
          .to.emit(LMTBridge, "TokensLocked")
          .withArgs(lmtAddress, otherAccount.address, amountOfTokensToLock);
        expect(await LMT.balanceOf(await LMTBridge.getAddress())).to.equal(
          amountOfTokensToLock
        );
        expect(
          await LMTBridge.lockedBalances(otherAccount.address, lmtAddress)
        ).to.equal(amountOfTokensToLock);
      });
    });

    context("User unlocking funds", function () {
      it("Should unlock tokens for the correct user", async function () {
        const { LMT, LMTBridge, owner, otherAccount } =
          await lockTokensFixture();

        const { v, r, s } = await prepareSignatureRelease(
          domainName,
          domainVersion,
          hardhatChainId,
          await LMTBridge.getAddress(),
          lmtAddress,
          await LMTBridge.owner(),
          otherAccount.address,
          amountOfTokensToLock,
          await LMTBridge.nonces(otherAccount.address)
        );

        expect(
          await LMTBridge.connect(otherAccount).unlockTokensWithSignature(
            lmtAddress,
            amountOfTokensToLock,
            otherAccount,
            v,
            r,
            s
          )
        )
          .to.emit(LMTBridge, "TokensUnlocked")
          .withArgs(otherAccount.address, amountOfTokensToLock);
      });
    });
  });

  describe("Reverts", function () {
    context("User locking funds", function () {
      it("Should revert if user tries to lock more than they has", async function () {
        const { LMT, LMTBridge, otherAccount } = await lockTokensFixture();
        await expect(
          LMTBridge.connect(otherAccount).lockTokens(
            lmtAddress,
            amountOfTokensToLock + 1
          )
        ).to.be.revertedWith("ERC20: insufficient allowance");
      });
      it("Should revert if user tries to lock 0", async function () {
        const { LMT, LMTBridge, otherAccount } = await deployContractsFixture();
        await LMT.mint(otherAccount.address, amountOfTokensToLock);
        await LMT.connect(otherAccount).approve(
          LMTBridge.getAddress(),
          amountOfTokensToLock
        );
        await expect(
          LMTBridge.connect(otherAccount).lockTokens(lmtAddress, 0)
        ).to.be.revertedWith("LMTBridge: Amount must be greater than 0");
      });
      it("Should revert if user tries to lock unsupported token", async function () {
        const { LMT, LMTBridge, otherAccount } = await deployContractsFixture();
        await LMT.mint(otherAccount.address, amountOfTokensToLock);
        await LMT.connect(otherAccount).approve(
          LMTBridge.getAddress(),
          amountOfTokensToLock
        );
        await expect(
          LMTBridge.connect(otherAccount).lockTokens(
            await LMT.getAddress(),
            amountOfTokensToLock
          )
        ).to.be.revertedWith("LMTBridge: Token not supported");
      });
    });
    context("Unlocking funds", function () {
      it("Should revert if owner tries to unlock 0", async function () {
        const { LMT, LMTBridge, otherAccount } = await lockTokensFixture();
        await LMT.connect(otherAccount).approve(
          LMTBridge.getAddress(),
          amountOfTokensToLock
        );
        const { v, r, s } = await prepareSignatureRelease(
          domainName,
          domainVersion,
          hardhatChainId,
          await LMTBridge.getAddress(),
          lmtAddress,
          await LMTBridge.owner(),
          otherAccount.address,
          amountOfTokensToLock,
          await LMTBridge.nonces(otherAccount.address)
        );
        await expect(
          LMTBridge.unlockTokensWithSignature(
            lmtAddress,
            0,
            otherAccount.address,
            v,
            r,
            s
          )
        ).to.be.revertedWith("LMTBridge: Amount must be greater than 0");
      });
      it("Should revert if wrong signer has signed the signature", async function () {
        const { LMT, LMTBridge, otherAccount } = await lockTokensFixture();

        const { v, r, s } = await prepareSignatureRelease(
          domainName,
          domainVersion,
          hardhatChainId,
          await LMTBridge.getAddress(),
          lmtAddress,
          otherAccount.address,
          otherAccount.address,
          amountOfTokensToLock,
          await LMTBridge.nonces(otherAccount.address)
        );

        await expect(
          LMTBridge.connect(otherAccount).unlockTokensWithSignature(
            lmtAddress,
            amountOfTokensToLock,
            otherAccount.address,
            v,
            r,
            s
          )
        ).to.be.revertedWith("LMTBridge: Invalid signature");
      });
      it("Should revert if owner tries to unlock more than a user they has", async function () {
        const { LMT, LMTBridge, otherAccount } = await lockTokensFixture();

        const { v, r, s } = await prepareSignatureRelease(
          domainName,
          domainVersion,
          hardhatChainId,
          await LMTBridge.getAddress(),
          lmtAddress,
          otherAccount.address,
          otherAccount.address,
          amountOfTokensToLock + 1,
          await LMTBridge.nonces(otherAccount.address)
        );

        await expect(
          LMTBridge.unlockTokensWithSignature(
            lmtAddress,
            amountOfTokensToLock + 1,
            otherAccount.address,
            v,
            r,
            s
          )
        ).to.be.revertedWith(
          "LMTBridge: Amount must be less than or equal locked balance"
        );
      });
    });
  });
});
