// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script{
    function createSubscriptionUsingConfig() public returns (uint64){
    HelperConfig helperConfig = new HelperConfig();    
    (,,address vrfCordinator,,,,,) = helperConfig.activeNetworkConfig();
    return createSubsciption(vrfCordinator);
    }

    function createSubsciption(address vrfCooridator) public returns (uint64){
        console.log("Creating subscription on ChainId " ,block.chainid);
        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(vrfCooridator).createSubscription();
        vm.stopBroadcast();
        console.log("Your subscription id is " ,subId);
        console.log("Please update subscriptionId in HelperConfig.s.sol");

        return subId;
    }

    function run() external returns (uint64){
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script{
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig(); 

        (,,address vrfCordinator,,uint64 subId, ,address link,) = helperConfig.activeNetworkConfig();

        fundSubscription(vrfCordinator, subId, link);
    }

    function fundSubscription(address vrfCoordinator, uint64 subId, address link) public{
        console.log("Funding subscription: ", subId);
        console.log("Vrf cooridnatior: ", vrfCoordinator);
        console.log("On ChainId: ", block.chainid);

        if(block.chainid == 31337){
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subId, FUND_AMOUNT);
            vm.stopBroadcast();
        }
        else {
            vm.startBroadcast();
            LinkToken(link).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
    }
     function run() external{
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script{
    function addConsummerUsingConfig(address raffle) public {
        HelperConfig helperConfig = new HelperConfig();

         (,,address vrfCordinator,,uint64 subId,,, uint256 deployerKey) = helperConfig.activeNetworkConfig();
         addConsumer(raffle, vrfCordinator, subId, deployerKey);
    }

    function addConsumer(address raffle, address vrfCordinator, uint64 subId, uint256 deployerKey) public {
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock(vrfCordinator).addConsumer(subId, raffle);
        vm.stopBroadcast();
    }

    function run() external{
        address raffle = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );

        addConsummerUsingConfig(raffle);
    }
}