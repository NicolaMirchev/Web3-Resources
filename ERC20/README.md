## What does the project do?
- In the project we implement a contract, which follows the ERC20 standard for a custom token.
- We also use OpenZeppelin library implementation to introduce a contract, which inherit the standard
- We implement scripts for deployment of the contract on different networks (local/testnet) and tests  

## Setup

Clone this repo

```
git clone https://github.com/NikolaMirchev/ERC20
cd FundMeProject
```

## Usage

Run

```
forge compile
```

Deploy The contract

```
forge script script/DeployOurToken.s.sol --private-key <PRIVATE_KEY> --rpc-url <ALCHEMY_URL>
```
