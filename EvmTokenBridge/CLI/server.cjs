// server.cjs

require("dotenv").config();
var express = require("express");
const app = express();
const { prepareSignature, prepareSignatureUnlock } = require("./utils.cjs");
const {
  destinationSigner,
  sourceSigner,
  usersRef,
  bridgeContract,
} = require("./config.cjs");
const { onServerStart } = require("./indexer.cjs");
// ------ Environment config ------

const port = process.env.PORT || 3000;

const blockSource = process.argv[2];
const blockDestination = process.argv[3];

onServerStart(blockSource, blockDestination);

// ------ API endpoints ------
// Return all user entries, which have to claim tokens on destination chain
app.get("/for-claim", async (req, res) => {
  try {
    const usersRefSnapshot = await usersRef.once("value");
    const users = [];

    usersRefSnapshot.forEach((userSnapshot) => {
      const user = userSnapshot.val();

      // Check if the user has tokens
      if (user.tokens) {
        // Iterate through the user's tokens
        Object.entries(user.tokens).forEach(([tokenId, tokenData]) => {
          console.log("Token data: ", tokenData);
          if (tokenData.bridgedAmount < tokenData.lockedAmount) {
            users.push({
              userId: userSnapshot.key,
              tokenId,
              tokenData,
            });
          }
        });
      }
    });

    // Send the users array as a response
    res.send(users);
  } catch (error) {
    console.log("Error trying to get tokens for claim: ", error);
    // Handle the error and send an appropriate response
    res.status(500).send("Internal Server Error");
  }
});
// Return all user entries, which have to release tokens on source chain
app.get("/for-release", async (req, res) => {
  try {
    const userSnapshot = await usersRef.once("value");
    const users = [];
    userSnapshot.forEach((snapshot) => {
      const user = snapshot.val();

      // Check if the user has tokens
      if (user.tokens) {
        // Iterate through the user's tokens
        Object.entries(user.tokens).forEach(([tokenId, tokenData]) => {
          if (tokenData.releasedAmount < tokenData.burnedAmount) {
            users.push({
              userId: snapshot.key,
              tokenId,
              tokenData,
            });
          }
        });
      }
    });
    res.send(users);
  } catch (error) {
    console.log("Error trying to get tokens for release: ", error);
    // Handle the error and send an appropriate response
    res.status(500).send("Internal Server Error");
  }
});

// Return all tokens, which a user has bridged
app.get("/all-bridged/:user", async (req, res) => {
  try {
    const user = req.params.user;
    const usersSnapshot = await usersRef.once("value");
    const result = { user: usersSnapshot.val(), tokens: [] };
    usersSnapshot.forEach((snapshot) => {
      if (snapshot.val() == user) {
        if (snapshot.val().tokens) {
          // Iterate through the user's tokens
          Object.entries(user.tokens).forEach(([tokenId, tokenData]) => {
            if (tokenData.bridgedAmount > 0) {
              result.tokens.push({
                tokenId,
              });
            }
          });
        }
      }
    });
    res.send(result);
  } catch (error) {
    console.log("API error obtaining user bridged tokens" + error);
    // Handle the error and send an appropriate response
    res.status(500).send("Internal Server Error");
  }
});

// Return all bridged tokens
app.get("/all-bridged-tokens", async (req, res) => {
  try {
    const userSnapshot = await usersRef.once("value");
    let result = [];
    userSnapshot.forEach((snapshot) => {
      const user = snapshot.val();
      if (user.tokens) {
        // Iterate through the user's tokens
        Object.entries(user.tokens).forEach(([tokenId, tokenData]) => {
          if (tokenData.bridgedAmount > 0) {
            result.push({
              tokenId,
            });
          }
        });
      }
    });

    res.send(result);
  } catch (error) {
    console.log("Error trying to get all bridged tokens " + error);
    // Handle the error and send an appropriate response
    res.status(500).send("Internal Server Error");
  }
});

// Return a signature for claiming all unclaimed tokens for a user
app.get("/claim-all/:user/:token", async (req, res) => {
  try {
    let result;
    const user = req.params.user;
    const token = req.params.token;
    const tokenSnapshot = await usersRef
      .child(user)
      .child("tokens")
      .child(token)
      .once("value");
    if (await tokenSnapshot.exists()) {
      const tokenData = tokenSnapshot.val();
      if (tokenData.bridgedAmount < tokenData.lockedAmount) {
        const werc20 = contracts.find(
          (contract) => contract.token === tokenData.token
        ).contract;
        const domainData = await werc20.eip712Domain();
        result = await prepareSignature(
          domainData.at(1),
          Number(domainData.at(2)),
          Number(domainData.at(3)),
          tokenData.token,
          destinationSigner,
          user,
          tokenData.lockedAmount - tokenData.bridgedAmount,
          await werc20.nonces(user)
        );
      }
    } else {
      res.status(404).send("Data not found");
    }

    res.send(result);
  } catch (error) {
    console.log("Error trying to get all bridged tokens " + error);
    // Handle the error and send an appropriate response
    res.status(500).send("Internal Server Error");
  }
});

// Return a signature for releasing all unclaimed tokens for a user
app.get("/release-all/:user/:token", async (req, res) => {
  try {
    let result;
    const user = req.params.user;
    const token = req.params.token;
    const tokenSnapshot = await usersRef
      .child(user)
      .child("tokens")
      .child(token)
      .once("value");
    if (await tokenSnapshot.exists()) {
      const tokenData = tokenSnapshot.val();
      if (tokenData.releasedAmount < tokenData.burnedAmount) {
        const domainData = await bridgeContract.eip712Domain();
        result = await prepareSignatureUnlock(
          domainData.at(1),
          Number(domainData.at(2)),
          Number(domainData.at(3)),
          await bridgeContract.getAddress(),
          token,
          sourceSigner,
          user,
          tokenData.burnedAmount - tokenData.releasedAmount,
          await bridgeContract.nonces(user)
        );
        result.amount = tokenData.burnedAmount - tokenData.releasedAmount;
      }
    } else {
      res.status(404).send("Data not found");
    }

    res.send(result);
  } catch (error) {
    console.log("Error trying to get all bridged tokens " + error);
    // Handle the error and send an appropriate response
    res.status(500).send("Internal Server Error");
  }
});

app.listen(port, () => {
  console.log("App is running on port: ", port);
});
