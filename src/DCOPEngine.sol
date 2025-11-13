// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {DCOP} from "./DCOP.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title DCOP Engine
 * @author Santiago Marin.
 *
 * 1 Token == 1 COP peg.
 * @notice This contract is the engine of the DCOP protocol, it is responsible for the minting and burning of DCOP tokens.
 * DCOP system should always be overcollateralized
 */
contract DCOPEngine is ReentrancyGuard {
    //////////// Errors ////////////
    error NeedsMoreThanZero();
    error TokensAndPriceFeedsLengthMismatch();
    error NotAllowedToken();
    error TransferFailed();
    error HealthFactorIsNotHealthy();
    error MintFailed();

    ////////// State Variables ///////
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant DCOP_PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1;

    mapping(address token => address priceFeed) private s_tokenToPriceFeed;
    mapping(address user => mapping(address token => uint256 collateral)) private s_userToCollateral;
    mapping(address user => uint256 dcopMinted) private s_userToDCOPMinted;
    address[] private s_collateralTokens;

    DCOP private immutable i_dcop;

    ////////// Events ///////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);

    /////////// Modifiers. ///////////
    modifier moreThanZero(uint256 amount) {
        if (amount <= 0) {
            revert NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_tokenToPriceFeed[token] == address(0)) {
            revert NotAllowedToken();
        }
        _;
    }

    /////////// Functions. ///////////
    constructor(
        address[] memory _tokenAddresses, 
        address[] memory _priceFeedAddresses, 
        address _dcopAddress) 
    {
        if (_tokenAddresses.length != _priceFeedAddresses.length) {
            revert TokensAndPriceFeedsLengthMismatch();
        }

        // COP Price feed
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            s_tokenToPriceFeed[_tokenAddresses[i]] = _priceFeedAddresses[i];
            s_collateralTokens.push(_tokenAddresses[i]);
        }

        i_dcop = DCOP(_dcopAddress);
    }

    function depositCollateralAndMint() external {}

    /**
     * @notice Deposits collateral into the DCOP system and mints DCOP tokens.
     * @param tokenCollateralAddress The address of the collateral token.
     * @param amountCollateral The amount of collateral to deposit.
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_userToCollateral[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);

        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert TransferFailed();
        }
    }

    function redeemForCollateral() external {}

    function redeemCollateral() external {}

    function mint(uint256 amountDCOPToMint) 
        external 
        moreThanZero(amountDCOPToMint) 
        nonReentrant {
            s_userToDCOPMinted[msg.sender] += amountDCOPToMint;
            _revertIfHealthFactorIsNotHealthy(msg.sender);

            bool minted = i_dcop.mint(msg.sender, amountDCOPToMint);
            if (!minted) {
                revert MintFailed();
            }
        }

    function burn() external {}

    function liquidate() external {}

    function getHealthFactor() external view returns (uint256) {}    

    ///////// private & internal functions ///////////

    function _getAccountInformation(address user) 
        private 
        view 
        returns (uint256 totalMinted, uint256 collateralValueInCOP) 
    {
        totalMinted = s_userToDCOPMinted[user];
        collateralValueInCOP = getAccountCollateralValueInCOP(user);
        return (totalMinted, collateralValueInCOP);
    }
        
    /**
     * @notice Returns how close to liquidation a user is.
     * If a user hf goes below 1, they can get liquidated.
     * @param user The address of the user.
     * @return The health factor of the user.
     */
    function _healthFactor(address user) private view returns (uint256) {
        // total dsc.
        // total colatteral value.
        (uint256 totalMinted, uint256 collateralValueInCOP) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold = 
        (collateralValueInCOP * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return collateralAdjustedForThreshold * DCOP_PRECISION / totalMinted;
    }

    function _revertIfHealthFactorIsNotHealthy(address user) private view {
        uint256 healthFactor = _healthFactor(user);
        if (healthFactor < MIN_HEALTH_FACTOR) {
            revert HealthFactorIsNotHealthy();
        }
    }

    /////// public & external view functions ///////
    // calculate how much we have in total collateral value in COP.
    function getAccountCollateralValueInCOP(address user) public view returns (uint256 collateralValueInCOP) {
        for(uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 collateralAmount = s_userToCollateral[user][token];
            collateralValueInCOP += getCOPValue(token, collateralAmount);
        }

        return collateralValueInCOP;
    }

    function getCOPValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_tokenToPriceFeed[token]);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / DCOP_PRECISION;
    }

}
