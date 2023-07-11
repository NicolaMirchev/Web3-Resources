// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.18;

// import {Test, console} from "forge-std/Test.sol";
// import {StdInvariant} from "forge-std/StdInvariant.sol";
// import {DeployDSC} from "../../script/DeployDSC.s.sol";
// import {DSCEngine} from "../../src/DSCEngine.sol";
// import {HelperConfig} from "../../script/HelperConfig.s.sol";
// import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// // 1. The total supply of DSC should be less than the total value of collateral
// // 2. Getter view functions should never revert <- evergreen invariant
// contract OpenInvariants is StdInvariant, Test{
//     DeployDSC deployer;
//     DSCEngine engine;
//     DecentralizedStableCoin coin;
//     HelperConfig config;
//     address weth;
//     address wbtc;

//     function setUp() external {
//          deployer = new DeployDSC();
//         (coin, engine, config) = deployer.run();
//         (,, weth, wbtc,) = config.activeNetworkConfig();
//         targetContract(address(engine));
//     }


//     function invariant_open_protocolMustHaveMoreValueThanTotalSupply() public view{
//         uint256 totalSupply = coin.totalSupply();
//         uint256 totalWethDeplosited = IERC20(weth).balanceOf(address(engine));
//         uint256 totalWbtcDeplosited = IERC20(wbtc).balanceOf(address(engine));
    
//         uint256 wethValue = engine.getUsdValue(weth, totalWethDeplosited);
//         uint256 wbtcValue = engine.getUsdValue(weth, totalWbtcDeplosited);

//         assert(wethValue + wbtcValue >= totalSupply);
//     }
// }
