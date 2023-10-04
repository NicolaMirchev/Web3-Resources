## What does the project do?
- In the project we implement a contract, which acts as a storage on the blockchain. We provide a functionallity to fund the contract.
- Only the owner of the contract can withdraw the funds in the contract.
- We use Chainlink price oracle for actual price conversion for ETH/USD (So we can check for minimum funding amount in USD)
- We implement scripts for deployment of the contract on different networks (local/testnet) and tests  

## Setup

Clone this repo

```
git clone https://github.com/NikolaMirchev/FundMeProject
cd FundMeProject
```

## Usage

Run

```
forge compile
```

Deploy The contract

```
forge script script/DeployFundMe.s.sol --private-key <PRIVATE_KEY> --rpc-url <ALCHEMY_URL>
```
