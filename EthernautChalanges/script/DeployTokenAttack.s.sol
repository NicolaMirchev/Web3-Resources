// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {Token} from "../src/Token.sol";

contract DeployTelephoneAttacker is Script{
    address public constant TOKEN_CONTRACT_ADDRESS = 0xe8f46E5C3a11083485Ed565684d2CcfFBC2526C2;
    


    function run() external{
        vm.startBroadcast();
        vm.stopBroadcast();
    }


}