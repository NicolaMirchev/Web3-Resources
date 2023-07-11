// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract Handler is Test{
    DSCEngine engine;
    DecentralizedStableCoin coin;
    ERC20Mock weth;
    ERC20Mock wbtc;
    uint256 MAX_DEPOSIT_SIZE = type(uint96).max;

    address[] public usersWithCollateralDeposited; 
    uint256 public timesMintIsCalled;
    MockV3Aggregator public ethUsdPriceFeed;

     constructor(DSCEngine _engine, DecentralizedStableCoin _coin){
        engine = _engine;
        coin = _coin;

        address[] memory collateralTokens = engine.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);

       ethUsdPriceFeed = MockV3Aggregator(engine.getCollateralPriceFeed(address(weth)));
    }

    // function updateCollateralPrice(uint96 newPrice) public{
    //     int256 newPriceInt = int256(uint256(newPrice));
    //     ethUsdPriceFeed.updateAnswer(newPriceInt);
    // }

    function depositCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        if(amountCollateral > MAX_DEPOSIT_SIZE) amountCollateral = MAX_DEPOSIT_SIZE;
        if(amountCollateral == 0) return;
        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, amountCollateral);
        collateral.approve(address(engine), amountCollateral);
        engine.depositCollateral(address(collateral), amountCollateral);
        usersWithCollateralDeposited.push(msg.sender);
    }

    function redeemCollateral(uint256 collateralSeed, uint256 amountCollateral) public{
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        uint256 maxCollateralToRedeem = engine.getCollateralBalanceOfIUser(msg.sender, address(collateral));
        if(amountCollateral >= maxCollateralToRedeem || maxCollateralToRedeem <= 0){
            return;
        }
        engine.redeemCollateral(address(collateral), amountCollateral);
    }

    function mintDsc(uint256 amount, uint256 addressSeed) public{        
        if(usersWithCollateralDeposited.length == 0) return;
        address sender = usersWithCollateralDeposited[addressSeed % usersWithCollateralDeposited.length];
        (uint256 totalMint,uint256 collateralValueInUsd) = engine.getAccountInformation(msg.sender); 

        uint256 maxDscToMint = (collateralValueInUsd / 2) - totalMint;
        if(maxDscToMint < 0){
            return;
        }
        if(amount > maxDscToMint) return;
        if(amount == 0) return;
        vm.startPrank(sender);
        engine.mintDsc(amount);
        vm.stopPrank();
        timesMintIsCalled++;
    }

    // Helper Fundtions
    function _getCollateralFromSeed(uint256 collateralSeed) private view returns(ERC20Mock){
        if(collateralSeed % 2 == 0){
            return weth;
        }
        return wbtc;
    }
}