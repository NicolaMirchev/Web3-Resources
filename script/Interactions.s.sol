// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";


contract FundFundMe is Script{
    uint256 constant SEND_VALUE = 0.01 ether;
    function fundFundMe(address mostRecenttyDeployeed) public{
        FundMe(payable(mostRecenttyDeployeed)).fund{value : SEND_VALUE}();
        console.log("Funded FundMe with %s", SEND_VALUE);
    }
    function run() external{
        vm.startBroadcast();
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        fundFundMe(mostRecentlyDeployed);
        vm.stopBroadcast();
    }
}

contract WithdrawFundMe is Script{
        uint256 constant SEND_VALUE = 0.01 ether;
    function withdrawFundMe(address mostRecenttyDeployeed) public{
        vm.startBroadcast();
        FundMe(payable(mostRecenttyDeployeed)).withdraw();
        vm.startBroadcast();
    }
    function run() external{
        vm.startBroadcast();
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        withdrawFundMe(mostRecentlyDeployed);
        vm.stopBroadcast();
    }
}