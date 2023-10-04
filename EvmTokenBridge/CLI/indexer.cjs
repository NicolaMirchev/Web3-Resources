const { prepareSignature, prepareSignatureUnlock } = require("./utils.cjs");
const db = require("./dbConfig.cjs");
const ethers = require("ethers");
const {
  BRIDGE_ADDRESS,
  bridgeContract,
  sourceSigner,
  destinationSigner,
  sourceProvider,
  destinationProvider,
  wERC20Abi,
  dbValues,
  sourceLastProccessedBlock,
  destinationlastProccessedBlockRef,
  usersRef,
} = require("./config.cjs");

const contracts = [];

// The function handles passed events, which has not been stored in db start to listen for new events.
async function onServerStart(startingBlockSource, startingBlockDestination) {
  handleEventsFromBlockSource(startingBlockSource);
  handleEventDestinationAndConstructTokens(startingBlockDestination);

  // We can add one more event listener, which will listen for tokens added and add them to contracts[].
  // Currently, if the token is new, we first construct it and add it to the contracts[] array.
  // Source chain
  bridgeContract.on("TokenLocked", async (token, user, amount, event) => {
    const currentUserRef = usersRef.child(user).child("tokens").child(token);

    // Here we should sign a transaction to mint tokens on the destination chain from the provider and return the signature.
    const destinationContract =
      await bridgeContract.destinationChainTokenAddresses(token);
    // If the token address is new, we should create new contract.
    if (!contracts.some((contract) => contract.token === destinationContract)) {
      addToken(token, destinationContract);
      await db
        .ref("contracts")
        .set({ source: token, destination: destinationContract });
    }
    wERC20 = contracts.find(
      (contract) => contract.token === destinationContract
    ).contract;

    const { r, s, v } = await prepareSignature(
      await wERC20.name(),
      destinationDomainVersion,
      mumbaiChainId,
      destinationContract,
      destinationSigner,
      user,
      amount,
      await wERC20.nonces(user)
    );
    try {
      const locked = await currentUserRef.child(dbValues.lockedAmount).get();

      if (locked.exists()) {
        currentUserRef
          .child(dbValues.lockedAmount)
          .set(locked.val() + Number(amount));
      } else {
        currentUserRef.child(dbValues.lockedAmount).set(Number(amount));
        currentUserRef.child(dbValues.bridgedAmount).set(0);
        currentUserRef.child(dbValues.releasedAmount).set(0);
        currentUserRef.child(dbValues.burnedAmount).set(0);
      }

      currentUserRef
        .child(dbValues.actionSignature)
        .child(dbValues.used)
        .set(false);
      currentUserRef.child(dbValues.actionSignature).child(dbValues.v).set(v);
      currentUserRef.child(dbValues.actionSignature).child(dbValues.r).set(r);
      currentUserRef.child(dbValues.actionSignature).child(dbValues.s).set(s);
    } catch (error) {
      console.log("Errror trying to input event data into db: " + error);
    }
    setLastProccessedBlock("source");
    console.log("R, s, v ", r, s, v);
  });
  // ------ Event listeners ------
  bridgeContract.on("TokenReleased", async (token, user, amount, event) => {
    try {
      const currentUserRef = usersRef.child(user).child("tokens").child(token);
      currentUserRef
        .child(dbValues.releasedAmount)
        .transaction((currentValue) => {
          return currentValue + Number(amount);
        });
      currentUserRef
        .child(dbValues.actionSignature)
        .child(dbValues.used)
        .set(true);

      // Write data to db.
    } catch (error) {
      console.log("Errror trying to input event data into db: " + error);
    }
    setLastProccessedBlock("source");
  });
}

async function handleEventsFromBlockSource(fromSourceBlockNumber) {
  const lastProccessedBlock = (await sourceLastProccessedBlock.get()).val();
  if (!fromSourceBlockNumber) {
    fromSourceBlockNumber = lastProccessedBlock;
  }
  const lastXblocks =
    (await sourceProvider.getBlockNumber()) - fromSourceBlockNumber;
  // If block number isn't provided, we get the latest block number.

  const lockedEvents = await bridgeContract.queryFilter(
    "TokenLocked",
    -lastXblocks
  );

  const releasedEvents = await bridgeContract.queryFilter(
    "TokenReleased",
    -lastXblocks
  );
  let lockedLastBlock = 0;
  lockedEvents.forEach(async (event) => {
    const tokenAddress = event.args[0];
    const user = event.args[1];
    const amount = event.args[2];
    if (lastProccessedBlock < event.blockNumber) {
      lockedLastBlock = event.blockNumber;
      await usersRef
        .child(user)
        .child("tokens")
        .child(tokenAddress)
        .child(dbValues.lockedAmount)
        .transaction((currentValue) => {
          return currentValue + Number(amount);
        });
    }
  });
  let releasedLastBlock = 0;
  releasedEvents.forEach(async (event) => {
    const tokenAddress = event.args[0];
    const user = event.args[1];
    const amount = event.args[2];
    if (lastProccessedBlock < event.blockNumber) {
      releasedLastBlock = event.blockNumber;
      usersRef
        .child(user)
        .child("tokens")
        .child(tokenAddress)
        .child(dbValues.releasedAmount)
        .transaction((currentValue) => {
          return currentValue + Number(amount);
        });
    }
  });

  if (lockedLastBlock > 0 || releasedLastBlock > 0) {
    db.ref("sourceLastProccessedBlock").set(
      lockedLastBlock > releasedLastBlock ? lockedLastBlock : releasedLastBlock
    );
  }
}
// The function proccess events from the source chain.
async function handleEventsFromBlockDestination(
  fromDestinationBlockNumber,
  wERC20,
  sourceTokenAddress
) {
  const lastProccessedBlock = (
    await destinationlastProccessedBlockRef.get()
  ).val();
  // If block number isn't provided, we get the latest block number.
  if (!fromDestinationBlockNumber) {
    fromDestinationBlockNumber = lastProccessedBlock;
  }
  const lastXblocks =
    (await sourceProvider.getBlockNumber()) - fromDestinationBlockNumber;

  const claimedEvents = await wERC20.queryFilter("TokenClaimed", -lastXblocks);

  const releasedEvents = await wERC20.queryFilter("TokenBurned", -lastXblocks);

  let claimedLastBlock = 0;
  claimedEvents.forEach(async (event) => {
    const user = event.args[1];
    const amount = event.args[2];
    if (lastProccessedBlock < event.blockNumber) {
      claimedLastBlock = event.blockNumber;
      await usersRef
        .child(user)
        .child("tokens")
        .child(sourceTokenAddress)
        .child(dbValues.bridgedAmount)
        .transaction((currentValue) => {
          return currentValue + Number(amount);
        });
    }
  });
  let burnedLastBlock = 0;
  releasedEvents.forEach(async (event) => {
    const user = event.args[1];
    const amount = event.args[2];
    if (lastProccessedBlock < event.blockNumber) {
      burnedLastBlock = event.blockNumber;
      usersRef
        .child(user)
        .child("tokens")
        .child(sourceTokenAddress)
        .child(dbValues.burnedAmount)
        .transaction((currentValue) => {
          return currentValue + Number(amount);
        });
    }
  });

  if (claimedLastBlock > 0 || burnedLastBlock > 0) {
    destinationlastProccessedBlockRef.set(
      claimedLastBlock > burnedLastBlock ? claimedLastBlock : burnedLastBlock
    );
  }
}
// The function proccess events from the destination chain, construct tokens and add them to contracts[].
async function handleEventDestinationAndConstructTokens(startingBlockNumber) {
  const snap = await db.ref("contracts").once("value");

  snap.forEach(async (snapshot) => {
    const { source, destination } = snap.val();

    if (source && destination) {
      const wERC20 = new ethers.Contract(
        destination,
        wERC20Abi,
        destinationProvider
      );
      await addToken(source, destination);
      handleEventsFromBlockDestination(startingBlockNumber, wERC20, source);
    }
  });
}

// The function sets the last proccessed block in the db.
async function setLastProccessedBlock(chain) {
  let lastBlock;
  if (chain == "source") {
    lastBlock = await sourceProvider.getBlockNumber();
    await sourceLastProccessedBlock.set(lastBlock);
  } else if (chain == "destination") {
    lastBlock = await destinationProvider.getBlockNumber();
    await destinationlastProccessedBlockRef.set(lastBlock);
  }
}

// The function add new token to db, construct contract instance and start event listener on it.
async function addToken(sourceAddress, destinationAddress) {
  const wERC20 = new ethers.Contract(
    destinationAddress,
    wERC20Abi,
    destinationProvider
  );
  contracts.push({ token: destinationAddress, contract: wERC20 });

  wERC20.on(
    "TokenClaimed",
    async (claimedTokenAddress, claimer, amount, event) => {
      try {
        await currentUserRef
          .child(dbValues.bridgedAmount)
          .transaction((currentValue) => {
            return currentValue + Number(amount);
          });

        await currentUserRef
          .child(dbValues.actionSignature)
          .child(dbValues.used)
          .set(true);
      } catch (error) {
        console.log("Errror trying to input event data into db: " + error);
      }
      console.log("Claimed event: ", claimer, amount);
      setLastProccessedBlock("destination");
    }
  );
  wERC20.on(
    "TokenBurned",
    async (burnedTokenAddress, burner, burnedAmount, event) => {
      const { r, s, v } = await prepareSignatureUnlock(
        sourceDomainName,
        sourceDomainVersion,
        sepoliaChainId,
        BRIDGE_ADDRESS,
        sourceAddress,
        sourceSigner,
        burner,
        burnedAmount,
        await bridgeContract.nonces(burner)
      );
      try {
        await currentUserRef
          .child(dbValues.burnedAmount)
          .transaction((currentValue) => {
            return currentValue + Number(amount);
          });
        currentUserRef.child(dbValues.actionSignature).child(dbValues.v).set(v);
        currentUserRef.child(dbValues.actionSignature).child(dbValues.r).set(r);
        currentUserRef.child(dbValues.actionSignature).child(dbValues.s).set(s);
        currentUserRef
          .child(dbValues.actionSignature)
          .child(dbValues.used)
          .set(false);
      } catch (error) {
        console.log("Errror trying to input event data into db: " + error);
      }
      setLastProccessedBlock("destination");
    }
  );
}

module.exports = { onServerStart };
