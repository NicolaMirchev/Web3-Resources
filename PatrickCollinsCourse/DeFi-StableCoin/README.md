## What does the project do?
- In the project we implement a ERC20 token, which is our stable coin.
- We implement another complex contract - DSCEngine, which is the owner of our ERC20 token. The engine take care of the collateral management for the users, who want to mine our stable coin. That makes our minting syteam "algorithmic".
- We use ChainLink pricefeed to peg our coin to the price of $1. That makes the system "Anchored or Pegged".
- Weth and Wbtc can be deposited in the engine, if the user want to mint our token. That makes the system "Exogenous".
- We use a health factor function implementation to track whether a user is eligible to mint more tokens and to determine when someone is eligible to liquidate. We monitor for 50% overcollateralization before allowing someone to redeem the debt of a liquidated user.
- We use unit tests to test most of the functions of the enigine.
- We use Fuzz testing to test the invariant of the engine. The invariant that we are testing is the the collateral inside the contract is always worth more than the minted tokens.

## Setup

Clone this repo

```
git clone https://github.com/NikolaMirchev/DeFi-StableCoin
cd DeFi-StableCoin
```

## Usage

Run

```
forge compile
```

Deploy The contract

```
forge script script/DeployDSC.s.sol --private-key <PRIVATE_KEY> --rpc-url <ALCHEMY_URL>
```
