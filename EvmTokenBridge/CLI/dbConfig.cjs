let firebase = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

const app = firebase.initializeApp({
  credential: firebase.credential.cert(serviceAccount),
  databaseURL:
    "https://lmtbridge-7668e-default-rtdb.europe-west1.firebasedatabase.app/",
});

const db = firebase.database(app);
module.exports = db;
