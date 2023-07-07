// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;


import {Script} from "forge-std/Script.sol";
import {BasicNft} from "../src/BasicNft.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract MintBasicNft is Script {
    string private PUG = "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("BasicNft", block.chainid);
        mintNftOnContract(mostRecentlyDeployed);
    }

    function mintNftOnContract(address contractAddress) public{
        vm.startBroadcast();
        BasicNft(contractAddress).mintNft(PUG);
        vm.stopBroadcast();
    }
}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           [2m:[0m [2mevm::cheatcodes[0m[2m:[0m non-empty stderr [3margs[0m[2m=[0m["bash", "/home/nikola_mirchev8/solidity-course/projects/nft/lib/foundry-devops/src/get_recent_deployment.sh", "BasicNft", "31337", "/home/nikola_mirchev8/solidity-course/projects/nft//broadcast"] [3mstderr[0m[2m=[0m"find: ‘/home/nikola_mirchev8/solidity-course/projects/nft//broadcast’: No such file or directory\n"
Traces:
^Z
[1]+  Stopped                 forge script script/Interactions.s.sol --ffi
[?2004h]0;nikola_mirchev8@LAPTOP-4QCB56TF: ~/solidity-course/projects/nft[01;32mnikola_mirchev8@LAPTOP-4QCB56TF[00m:[01;34m~/solidity-course/projects/nft[00m$ forge script script/Interactions.s.sol --ffi[Kgit push[Kcommit -m"Created custom ERC20 token using OpenZeppelin contracts"add .[Kcommit -m"Created custom ERC20 token using OpenZeppelin contracts"push[Kforge script script/Interactions.s.solgit push[Kcommit -m"Created custom ERC20 token using OpenZeppelin contracts"add .[Kforge testbuildinstall OpenZeppelin/openzeppelin-contracts --no-commit[K[K[K[K[Kgit config --list
[?2004l[?1h=user.email=<YOUR_EMAIL>[m
user.name=<YOUR_NAME>[m
core.repositoryformatversion=0[m
core.filemode=true[m
core.bare=false[m
core.logallrefupdates=true[m
submodule.lib/forge-std.url=https://github.com/foundry-rs/forge-std[m
submodule.lib/forge-std.active=true[m
submodule.lib/chainlink-brownie-contracts.url=https://github.com/smartcontractkit/chainlink-brownie-contracts[m
submodule.lib/chainlink-brownie-contracts.active=true[m
remote.Web3.url=https://github.com/NicolaMirchev/Web3Excercises.git[m
remote.Web3.fetch=+refs/heads/*:refs/remotes/Web3/*[m
submodule.lib/foundry-devops.url=https://github.com/Cyfrin/foundry-devops[m
submodule.lib/foundry-devops.active=true[m
remote.origin.url=https://github.com/NicolaMirchev/Web3Excercises.git[m
remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*[m
branch.master.remote=origin[m
branch.master.merge=refs/heads/master[m
branch.main.remote=origin[m
branch.main.merge=refs/heads/main[m
:[K[K-[Klog file: [Kaa[Kdd[Kaa[K^W^W[K^W^W[K[K[K[K[K[K:[K[K:[K[K:[K[H[2J[H[H[2J[Huser.email=<YOUR_EMAIL>[m
user.name=<YOUR_NAME>[m
core.repositoryformatversion=0[m
core.filemode=true[m
core.bare=false[m
core.logallrefupdates=true[m
submodule.lib/forge-std.url=https://github.com/foundry-rs/forge-std[m
submodule.lib/forge-std.active=true[m
submodule.lib/chainlink-brownie-contracts.url=https://github.com/smartcontractkit/chainlink-brownie-contracts[m
submodule.lib/chainlink-brownie-contracts.active=true[m
remote.Web3.url=https://github.com/NicolaMirchev/Web3Excercises.git[m
remote.Web3.fetch=+refs/heads/*:refs/remotes/Web3/*[m
submodule.lib/foundry-devops.url=https://github.com/Cyfrin/foundry-devops[m
submodule.lib/foundry-devops.active=true[m
remote.origin.url=https://github.com/NicolaMirchev/Web3Excercises.git[m
remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*[m
branch.master.remote=origin[m
branch.master.merge=refs/heads/master[m
branch.main.remote=origin[m
branch.main.merge=refs/heads/main[m
:[K[K:[K[H[2J[H[H[2J[Huser.email=<YOUR_EMAIL>[m
user.name=<YOUR_NAME>[m
core.repositoryformatversion=0[m
core.filemode=true[m
core.bare=false[m
core.logallrefupdates=true[m
submodule.lib/forge-std.url=https://github.com/foundry-rs/forge-std[m
submodule.lib/forge-std.active=true[m
submodule.lib/chainlink-brownie-contracts.url=https://github.com/smartcontractkit/chainlink-brownie-contracts[m
submodule.lib/chainlink-brownie-contracts.active=true[m
remote.Web3.url=https://github.com/NicolaMirchev/Web3Excercises.git[m
remote.Web3.fetch=+refs/heads/*:refs/remotes/Web3/*[m
submodule.lib/foundry-devops.url=https://github.com/Cyfrin/foundry-devops[m
submodule.lib/foundry-devops.active=true[m
remote.origin.url=https://github.com/NicolaMirchev/Web3Excercises.git[m
remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*[m
branch.master.remote=origin[m
branch.master.merge=refs/heads/master[m
branch.main.remote=origin[m
branch.main.merge=refs/heads/main[m
:[K[H[2J[H[H[2J[Huser.email=<YOUR_EMAIL>[m
user.name=<YOUR_NAME>[m
core.repositoryformatversion=0[m
core.filemode=true[m
core.bare=false[m
core.logallrefupdates=true[m
submodule.lib/forge-std.url=https://github.com/foundry-rs/forge-std[m
submodule.lib/forge-std.active=true[m
submodule.lib/chainlink-brownie-contracts.url=https://github.com/smartcontractkit/chainlink-brownie-contracts[m
submodule.lib/chainlink-brownie-contracts.active=true[m
remote.Web3.url=https://github.com/NicolaMirchev/Web3Excercises.git[m
remote.Web3.fetch=+refs/heads/*:refs/remotes/Web3/*[m
submodule.lib/foundry-devops.url=https://github.com/Cyfrin/foundry-devops[m
submodule.lib/foundry-devops.active=true[m
remote.origin.url=https://github.com/NicolaMirchev/Web3Excercises.git[m
remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*[m
branch.master.remote=origin[m
branch.master.merge=refs/heads/master[m
branch.main.remote=origin[m
branch.main.merge=refs/heads/main[m
:[K[H[2J[H[H[2J[Huser.email=<YOUR_EMAIL>[m
user.name=<YOUR_NAME>[m
core.repositoryformatversion=0[m
core.filemode=true[m
core.bare=false[m
core.logallrefupdates=true[m
submodule.lib/forge-std.url=https://github.com/foundry-rs/forge-std[m
submodule.lib/forge-std.active=true[m
submodule.lib/chainlink-brownie-contracts.url=https://github.com/smartcontractkit/chainlink-brownie-contracts[m
submodule.lib/chainlink-brownie-contracts.active=true[m
remote.Web3.url=https://github.com/NicolaMirchev/Web3Excercises.git[m
remote.Web3.fetch=+refs/heads/*:refs/remotes/Web3/*[m
submodule.lib/foundry-devops.url=https://github.com/Cyfrin/foundry-devops[m
submodule.lib/foundry-devops.active=true[m
remote.origin.url=https://github.com/NicolaMirchev/Web3Excercises.git[m
remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*[m
branch.master.remote=origin[m
branch.master.merge=refs/heads/master[m
branch.main.remote=origin[m
branch.main.merge=refs/heads/main[m
:[K[H[2J[H[H[2J[Huser.email=<YOUR_EMAIL>[m
user.name=<YOUR_NAME>[m
core.repositoryformatversion=0[m
core.filemode=true[m
core.bare=false[m
core.logallrefupdates=true[m
submodule.lib/forge-std.url=https://github.com/foundry-rs/forge-std[m
submodule.lib/forge-std.active=true[m
submodule.lib/chainlink-brownie-contracts.url=https://github.com/smartcontractkit/chainlink-brownie-contracts[m
submodule.lib/chainlink-brownie-contracts.active=true[m
remote.Web3.url=https://github.com/NicolaMirchev/Web3Excercises.git[m
remote.Web3.fetch=+refs/heads/*:refs/remotes/Web3/*[m
submodule.lib/foundry-devops.url=https://github.com/Cyfrin/foundry-devops[m
submodule.lib/foundry-devops.active=true[m
remote.origin.url=https://github.com/NicolaMirchev/Web3Excercises.git[m
remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*[m
branch.master.remote=origin[m
branch.master.merge=refs/heads/master[m
branch.main.remote=origin[m
branch.main.merge=refs/heads/main[m
:[K[Kpull.rebase=false[m
:[K[Ksubmodule.lottery/lib/forge-std.url=https://github.com/foundry-rs/forge-std[m
:[K[Ksubmodule.lottery/lib/forge-std.active=true[m
submodule.lottery/lib/chainlink-brownie-contracts.url=https://github.com/smartcontractkit/chainlink-brownie-contracts[m
submodule.lottery/lib/chainlink-brownie-contracts.active=true[m
submodule.lottery/lib/solmate.url=https://github.com/transmissions11/solmate[m
submodule.lottery/lib/solmate.active=true[m
submodule.lottery/lib/foundry-devops.url=https://github.com/ChainAccelOrg/foundry-devops[m
submodule.lottery/lib/foundry-devops.