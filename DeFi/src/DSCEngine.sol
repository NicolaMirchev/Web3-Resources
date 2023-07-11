// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/*@title DSCEngine
* @autor Nikola Mirchev
*   
*  The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg.
*  This stablecoin has the propertiesL
*   - Exogenous Collateral
*   - Dollar Pegged
*   - Algoritmically Stable
*
*   Our DSC system should always be "overcollateralized". At no point, should the value of all collateral <= the $ backed 
*   of all the DSC.
*
*   @notice This contarct is the core of the DSC System. It handles all the logic for minting and redeeming DSC, as well as depositing
* & withdrawing collateral.
*   @notice This contract is VERY loosely based on the MakerDAO DSS (DAI) system.
*/
contract DSCEngine is ReentrancyGuard {
    /////////// Errors ////////////
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error DSCEngine__TokenNotAllowed();
    error DSCEngine__TranferFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactor);
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorOk();
    error DSCEngine__HealthFactorNotImproved();

    /////////// State Variables ////////////
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // 200% overcollateralized
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant LIQUIDATION_BONUS = 10; // 10% bonus
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;

    DecentralizedStableCoin private immutable i_DSC;
    mapping(address token => address priceFeed) private s_priceFeeds; // tokenToPriceFeed
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    
    mapping(address user => uint256 amountDscMinted) private s_dscMinter;
    address[] private s_collateralTokens;

    /////////// Errors ////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    event CollateralRedeemed(address indexed redeemedFrom,address indexed redeemedTo, address indexed token, uint256 amount);

    /////////// Modifiers ////////////
    modifier moreThanZero(uint256 amount) {
        if (amount <= 0) revert DSCEngine__NeedsMoreThanZero();
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) revert DSCEngine__TokenNotAllowed();
        _;
    }

    /////////// Functions ////////////
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }
        i_DSC = DecentralizedStableCoin(dscAddress);
    }

    /////////// External Functions ////////////
    /**
     * @notice follows CEI
     * @param _tokenCollateralAddress The address to depisot as collateral
     * @param _amountCollateral  The amount of collateral deposited
     */
    function depositCollateral(address _tokenCollateralAddress, uint256 _amountCollateral)
        public
        moreThanZero(_amountCollateral)
        isAllowedToken(_tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][_tokenCollateralAddress] += _amountCollateral;
        emit CollateralDeposited(msg.sender, _tokenCollateralAddress, _amountCollateral);
        bool success = IERC20(_tokenCollateralAddress).transferFrom(msg.sender, address(this), _amountCollateral);

        if (!success) revert DSCEngine__TranferFailed();
    }
    // in order to redeem collateral:
    // 1. health factor must be over 1 AFTER collateral pulled
    // DRY: Don't repeat yourself
    // CEI: Check, Effects, Interactions
    function redeemCollateral(address tokenCollateralAddress, uint256 amount) public moreThanZero(amount) nonReentrant {
       _redeemCollatera(tokenCollateralAddress, amount, msg.sender, msg.sender);
    }

    /**
     * 
     * @param tokenCollateralAddress the address of the token to deposit as collateral
     * @param amountCollateral the amount of collateral to deposit
     * @param amountToMint  the amount of decentralized stablecoin to mint
     * @notice this function will deposit your collateral and mint DSC in one transaction 
     */
    function depositCollateralAndMintDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountToMint) external {
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintDsc(amountToMint);
    }
    function depositCollateralForDsc() external {}
    // 1. Check if the collateral value > DSC amount. Price feeds, values, etc.
    /**
     * 
     * @param amountDscToMint The amount of decentralized stablecoin to mint
     * @notice they must have more collateral value than the minimum threshold
     */
    function mintDsc(uint256 amountDscToMint) public moreThanZero(amountDscToMint) nonReentrant {
        s_dscMinter[msg.sender] += amountDscToMint;
        _revertIfHealthFactorIsBroken(msg.sender);

        bool minted = i_DSC.mint(msg.sender, amountDscToMint);
        if(!minted) revert DSCEngine__MintFailed();
    }

    function burnDsc(uint256 amount) public moreThanZero(amount) {
        _burnDsc(amount, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender); // Maybe this is unneccesarry
    }
    /**
     * 
     * @param tokenCollateral The collateral address to redeem
     * @param amountCollateral the amount collateral to redeem
     * @param amountDscToBurn the amount of DSC to burn
     * This function burns DSC and redeems underlying collateral in one transaction
     */
    function redeemCollateralForDsc(address tokenCollateral, uint256 amountCollateral, uint256 amountDscToBurn) external {
        burnDsc(amountDscToBurn);
        redeemCollateral(tokenCollateral, amountCollateral);
    }
    // If we do start nearing undercollaterization, we need someone to liquidate positions
    // $100 ETH backing $50 DSC
    // $20 ETG back $50 DSC <- DSC isn't worth $1
    // If someone is almost undercollateralized, we will pay to liquidate them!
    /**
     * 
     * @param collateral The erc20 collateral address to liquidate from the user
     * @param user The user who has broken the health factor. Their _healthFactor should be below Min_health_factor
     * @param debtToCover The amount of DSC you want to burn to imporove the users health factor
     * @notice You can parially liquidate a user.
     * @notice You will get a liquidation bonus for taking the users funds.
     * @notice This function working assumes the protocol will be roughtly 200% overcollateralized in order for this to work.
     * @notice A known bug would be if the protocol were 100% or less collateralized, then we wouldn't be able to incentive the
     * liquidators.
     * For example, if the price of the collateral plummeted before anyone could be liquidated
     */
    function liqidate(address collateral, address user, uint256 debtToCover) 
    external 
    moreThanZero(debtToCover)
    nonReentrant {
        uint256 startingUserHealthFactor = getHealthFactor(user);
        if(startingUserHealthFactor >= MIN_HEALTH_FACTOR) revert DSCEngine__HealthFactorOk();

        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(collateral, debtToCover);
        // We are giving them 10% bonus.
        // We should implement a feature to liquidate in the event the protocol is insolvent
        // And weep extra amount into trasury
        uint256 bounsCollateral = (tokenAmountFromDebtCovered * LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;
        uint256 totalCollateraltoRedeem = tokenAmountFromDebtCovered + bounsCollateral;
        _redeemCollatera(collateral, totalCollateraltoRedeem, user, msg.sender);
        _burnDsc(debtToCover, user, msg.sender);
        uint256 endingUserHealthFactor = _healthFactor(user);
        if(endingUserHealthFactor <= startingUserHealthFactor){
            revert DSCEngine__HealthFactorNotImproved();
        }
        _revertIfHealthFactorIsBroken(msg.sender);
    }
    function getHealthFactor(address user) public view returns (uint256) {
        return _healthFactor(user);
    }

    //////// Private and Internal View Functions ////////
    function _revertIfHealthFactorIsBroken(address user) internal view{
        uint256 userHealthFactor = _healthFactor(user);
        if(userHealthFactor < MIN_HEALTH_FACTOR) revert DSCEngine__BreaksHealthFactor(userHealthFactor);
        
    }

    function _redeemCollatera(address tokenCollateralAddress, uint256 amount, address from, address to)
    private{
        s_collateralDeposited[from][tokenCollateralAddress] -= amount;
        emit CollateralRedeemed(from, to, tokenCollateralAddress, amount);
        // _calculateHealthFactorAfter()
        bool success = IERC20(tokenCollateralAddress).transfer(to, amount);
        if(!success) revert DSCEngine__TranferFailed();
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    /* @dev Low-level internal function, do not call if the call function is not checking the health factor.
    */
    function _burnDsc(uint256 amountToBurn, address onBehalfOf, address dscFrom) private{
        s_dscMinter[onBehalfOf] -= amountToBurn;
        bool success = i_DSC.transferFrom(dscFrom, address(this), amountToBurn);
        if(!success) revert DSCEngine__TranferFailed();
        i_DSC.burn(amountToBurn);
       }

    function _getAccountInformation(address user) private view returns (uint256 totalDscMinted, uint256 collateralValueInUsd){
        totalDscMinted = s_dscMinter[user];
        collateralValueInUsd = getAccountCollateralValue(user);

        return (totalDscMinted, collateralValueInUsd);
    }

    /**
     * 
     * Returns how close to liquidation a user is 
     * If a user goes below 1, then they can get liquidated
     */
    function _healthFactor(address user) private view returns (uint256){
        // total DSC minted
        // total collateral VALUE
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
        if(totalDscMinted <= 0) return 1e18;
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }

    ////// public and external view functions ///////
    function getAccountCollateralValue(address user) public view returns(uint256 totalCollateralValueInUsd){
        uint256 length = s_collateralTokens.length;
        for(uint256 i = 0; i< length; i++){
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount); 
        }
        return totalCollateralValueInUsd;
    }

    function getUsdValue(address token, uint256 amount) public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (,int256 price,,,) = priceFeed.latestRoundData();
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;
    }

    function getTokenAmountFromUsd(address collateral, uint256 usdValueInWei) public view returns(uint256){
        // price of ETH (token)
        // $/ETH ??
        // 
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[collateral]);
        (,int256 price , , , ) = priceFeed.latestRoundData();
        return (usdValueInWei * PRECISION) / (uint256(price) * ADDITIONAL_FEED_PRECISION);
    }

    function getAccountInformation(address user) external view returns(uint256 totalDscMinted, uint256 collateralValueInUsd){
        return _getAccountInformation(user);
    }
}
