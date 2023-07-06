// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract HelperConfig is Script{
    struct NewtworkConfig{
        uint256 entranceFee;
        uint256 interval;
        address vrfCordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address link;
        uint256 deployerKey;
    }

    NewtworkConfig public activeNetworkConfig;
    uint256 public constant DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor(){
        if(block.chainid == 11155111){
            activeNetworkConfig = getSepoliaEthConfig();
        }
        else{
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    function getSepoliaEthConfig() public view returns(NewtworkConfig memory){
        return NewtworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCordinator: 	0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            gasLane : 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId : 1893,
            callbackGasLimit: 500000, // 500,000 gas!
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            deployerKey : vm.envUint("PRIVATE_KEY")
        });
    }

      function getOrCreateAnvilConfig() public returns(NewtworkConfig memory){
        if(activeNetworkConfig.vrfCordinator != address(0)){
            return activeNetworkConfig;
        }
        uint96 baseFee = 0.25 ether;
        uint96 gasPriceLink = 1e9;
        
        vm.startBroadcast();
        VRFCoordinatorV2Mock fRFCoordinatorV2Mock = new VRFCoordinatorV2Mock(baseFee, gasPriceLink);
        LinkToken link = new LinkToken();
        vm.stopBroadcast();

        return NewtworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCordinator: 	address(fRFCoordinatorV2Mock),
            gasLane : 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId : 0, // our scpript will add this.
            callbackGasLimit: 500000, // 500,000 gas!
            link: address(link),
            deployerKey: DEFAULT_ANVIL_KEY
        });
    }

 
}