## What does the project do?

- In the project we impement UUPSUpgradable contract extending the predefined contracts from OpenZeppelin.
- We use ERC1967Proxy to establish a proxy with the different address of implementations for the contract.
- We implement deploy script, so we can manage the implementations.
- We have a test to see if the logic is changing, when the address of the implementation is changed.

## Setup

Clone this repo

```
git clone https://github.com/NikolaMirchev/UpgradableContract
cd UpgradableContract
```

## Usage

Run

```
forge compile
```

Deploy The contract:

```
forge script script/DeployBox.s.sol --private-key <PRIVATE_KEY> --rpc-url <ALCHEMY_URL>
```

Upgrade the contract to execute logic from implementation of 'Box2':

```
forge script script/UpgradeBox.s.sol --private-key <PRIVATE_KEY> --rpc-url <ALCHEMY_URL>
```
