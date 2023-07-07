// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {BasicNft} from "../src/BasicNft.sol";

contract DeployBasicNft is Script{

    function run() external returns (BasicNft){
        vm.startBroadcast();
        BasicNft nft = new BasicNft();
        vm.stopBroadcast();
        return nft;
    }
}