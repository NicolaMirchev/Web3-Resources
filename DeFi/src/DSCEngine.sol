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

    /////////// State Variables ////////////
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // 200% overcollateralized
    uint256 private constant LIQUIDATION_PRECISION = 50;
    uint256 private constant MIN_HEALTH_FACTOR = 1;

    DecentralizedStableCoin private immutable i_DSC;
    mapping(address token => address priceFeed) private s_priceFeeds; // tokenToPriceFeed
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    
    mapping(address user => uint256 amountDscMinted) private s_dscMinter;
    address[] private s_collateralTokens;

    /////////// Errors ////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

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
        external
        moreThanZero(_amountCollateral)
        isAllowedToken(_tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][_tokenCollateralAddress] += _amountCollateral;
        emit CollateralDeposited(msg.sender, _tokenCollateralAddress, _amountCollateral);
        bool success = IERC20(_tokenCollateralAddress).transferFrom(msg.sender, address(this), _amountCollateral);

        if (!success) revert DSCEngine__TranferFailed();
    }

    function redeemCollateral() external {}

    function depositCollateralAndMintDsc() external {}
    function depositCollateralForDsc() external {}
    // 1. Check if the collateral value > DSC amount. Price feeds, values, etc.
    /**
     * 
     * @param amountDscToMint The amount of decentralized stablecoin to mint
     * @notice they must have more collateral value than the minimum threshold
     */
    function mintDsc(uint256 amountDscToMint) external moreThanZero(amountDscToMint) nonReentrant {
        s_dscMinter[msg.sender] += amountDscToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
    }
    function burnDsc() external {}
    function redeemCollateralForDsc() external {}
    function liqidate() external {}
    function getHealthFactor() external view {}

    //////// Private and Internal View Functions ////////
    function _revertIfHealthFactorIsBroken(address user) internal view{
        uint256 userHealthFactor = _healthFactor(user);
        if(userHealthFactor < MIN_HEALTH_FACTOR) revert DSCEngine__BreaksHealthFactor(userHealthFactor);
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
}
