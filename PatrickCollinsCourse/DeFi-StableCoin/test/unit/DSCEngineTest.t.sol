// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract DSCEngineTest is Test{
    DeployDSC deployer;
    DecentralizedStableCoin coin;
    DSCEngine engine;
    HelperConfig config;
    address ethUsdPriceFeed;
    address weth;

    address public USER = makeAddr("User");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;
    uint256 public constant AMOUNT_DSC_TO_MINT = 200000000000000000;

    function setUp() public{
        deployer = new DeployDSC();
        (coin, engine, config) = deployer.run();
        (ethUsdPriceFeed, ,weth,,) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(USER,STARTING_ERC20_BALANCE);
    }

    address[] tokenAddresses;
    address[] priceFeedAddressess;
    /////// depositCollateral Tests ////////
    function testRevertIfTokenLengthDoesntMatchPriceFeed() public{
        tokenAddresses.push(weth);
        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddressess, address(coin));
    }
    ////////////////////////////
    /////// Price Tests ////////
    ////////////////////////////
    function testGetUsdValue() public{
        uint256 ethAmount = 15e18;
        // 15e18 * 2000/Eth = 30,3000e18
        console.log(ethUsdPriceFeed);

        uint256 expectedUsd = 30000e18;
        uint256 actiualUsd = engine.getUsdValue(weth, ethAmount);
        assertEq(expectedUsd, actiualUsd);
    }

    function testGetTokenAmountFromUsd() public{
        uint256 usdAmount = 100 ether;
        uint256 expectedWeth = 0.05 ether;
        uint256 actualWeth = engine.getTokenAmountFromUsd(weth,usdAmount);
        assertEq(expectedWeth,actualWeth);
    }

    ////////////////////////////////////////    
    /////// depositCollateral Tests ////////
    ////////////////////////////////////////

    function testRevertIfCollateralZero() public{
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        engine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertsWithUnapprovedCollateral() public{
        ERC20Mock ranToken = new ERC20Mock();
        ranToken.mint(USER, AMOUNT_COLLATERAL);
        vm.startPrank(USER);

        vm.expectRevert(DSCEngine.DSCEngine__TokenNotAllowed.selector);
        engine.depositCollateral(address(ranToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    modifier mintDSC() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.mintDsc(AMOUNT_DSC_TO_MINT);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralAndGetAccountInfo() depositedCollateral public{
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(USER);

        uint256 expectedTotalDscMinted = 0;
        uint256 expectedDepositAmount = engine.getTokenAmountFromUsd(weth, collateralValueInUsd);

        assertEq(totalDscMinted, expectedTotalDscMinted);
        assertEq(AMOUNT_COLLATERAL, expectedDepositAmount);
    }
    ////////////////////////////////////////////////
    ///////// redeemCollateral and mintDsc /////////
    ////////////////////////////////////////////////
     //function redeemCollateral(address tokenCollateralAddress, uint256 amount)

     function testRedeemCollateralTransactAllCollateralValue() public depositedCollateral {
        assertEq(0, ERC20Mock(weth).balanceOf(USER));

        vm.prank(USER);
        engine.redeemCollateral(address(weth), AMOUNT_COLLATERAL);

        assertEq(AMOUNT_COLLATERAL, ERC20Mock(weth).balanceOf(USER));
    }

   // function depositCollateralAndMintDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountToMint) 

    function testDepositAndMintForValidAmount() public{
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateralAndMintDsc(weth, AMOUNT_COLLATERAL, AMOUNT_DSC_TO_MINT);
        vm.stopPrank();

        (uint256 totalDscMinted,) = engine.getAccountInformation(USER);

        assertEq(totalDscMinted, AMOUNT_DSC_TO_MINT);
    }

    
    function testRedeemAndBurnForValidData() depositedCollateral mintDSC public{
        vm.startPrank(USER);
        DecentralizedStableCoin(coin).approve(address(engine), AMOUNT_DSC_TO_MINT);
        engine.redeemCollateralForDsc(weth, AMOUNT_COLLATERAL, AMOUNT_DSC_TO_MINT );
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(USER);

        assertEq(totalDscMinted, 0);
        assertEq(collateralValueInUsd, 0);
    }

    function testReedemCollateralForNotDepositedUnderflows() depositedCollateral mintDSC public{
        // 1. Deposit some collateral in from account A.
        DecentralizedStableCoin(coin).approve(address(engine), AMOUNT_DSC_TO_MINT); 
        address attacker = makeAddr("attacker");

        vm.startPrank(attacker);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        // 2. Redeem the same collateral from account B with burnDsc value 0.
        engine.redeemCollateral(weth, 10, 0);

        console.log(engine.getAccountCollateralValue(attacker));
        assert(engine.getAccountCollateralValue(attacker) > 0);   
    }
}