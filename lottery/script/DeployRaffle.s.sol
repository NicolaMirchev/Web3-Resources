// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns(Raffle, HelperConfig){
        HelperConfig helperConfig = new HelperConfig();
        ( uint256 entranceFee,
        uint256 interval,
        address vrfCordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit, address link, uint256 deployerKey) = helperConfig.activeNetworkConfig();

        if(subscriptionId == 0){
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubsciption(vrfCordinator);
        }

        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscription(vrfCordinator, subscriptionId, link);

        vm.startBroadcast();
        Raffle raffle = new Raffle(entranceFee, interval, vrfCordinator, gasLane, subscriptionId, callbackGasLimit);
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), vrfCordinator, subscriptionId, deployerKey);
        return (raffle, helperConfig);
    }
}