## What does the project do?
- In the project we implement a ERC721 standard using the OpenZeppelin implementation.
- We have a contract, which stores the nftUri on IPSF and another one which is storing NFTs as SVG on-chain.
- For the on-chain NFT we provide functionality to change the appearance of the token.
- We use byte64 encoding and abi.encodePacked() to implement the on-chain solution.
- We implement scripts for deployment of the contract on different networks (local/testnet) and tests  .

## Setup

Clone this repo

```
git clone https://github.com/NikolaMirchev/NFT
cd NFT
```

## Usage

Run

```
forge compile
```

Deploy The contract

```
forge script script/DeployMoodNft.s.sol --private-key <PRIVATE_KEY> --rpc-url <ALCHEMY_URL>
```
