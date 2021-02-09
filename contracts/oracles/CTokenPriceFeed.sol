/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "@paulrberg/contracts/math/CarefulMath.sol";
import "../external/chainlink/AggregatorV3Interface.sol";
import "../external/compound/CTokenInterface.sol";


/**
 * @title CTokenPriceFeed
 * @author Hifi
 * @notice Provides the USD price of a cToken
 */
contract CTokenPriceFeed is
    AggregatorV3Interface, /* no dependency */
    CarefulMath /* no dependency */
{
    string internal internalDescription;
    CTokenInterface public cToken;
    AggregatorV3Interface public priceFeed;

    /**
     * @param description_ The description of the price feed, e.g. "cWBTC/USD"
     * @param cToken_ The address of the cToken
     * @param priceFeed_ The Chainlink price feed providing the USD price of the underlying of the cToken
     */
    constructor(
      string memory description_,
      address cToken_,
      address priceFeed_
    ) {
        internalDescription = description_;
        cToken = CTokenInterface(cToken_);
        priceFeed = AggregatorV3Interface(priceFeed_);
    }

    /**
     * @dev Returns the number of decimals
     * @return The number of decimals (always 8)
     */
    function decimals() external pure override returns (uint8) {
        return 8;
    }

    /**
     * @dev Returns the description of the price feed
     * @return The description of the price feed
     */
    function description() external view override returns (string memory) {
        return internalDescription;
    }

    /**
     * @dev Returns the version of the contract
     * @return The version of the contract
     */
    function version() external pure override returns (uint256) {
        return 1;
    }

    /**
     * @dev Returns the price of the latest round
     * @param roundId_ This parameter not used but mandatory to comply to the interface
     * @return roundId Same value as roundId_
     * @return answer The price of the cToken in USD
     * @return startedAt Unused value, always 0
     * @return updatedAt Unused value, always 0
     * @return answeredInRound Unused value, always 0
     */
    function getRoundData(uint80 roundId_)
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (roundId_, getPrice(), 0, 0, 0);
    }

    /**
     * @dev Returns the price of the latest round
     * @return roundId Unused value, always 0
     * @return answer The price of the cToken in USD
     * @return startedAt Unused value, always 0
     * @return updatedAt Unused value, always 0
     * @return answeredInRound Unused value, always 0
     */
    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (0, getPrice(), 0, 0, 0);
    }

    /**
     * @dev Get the USD price of the cToken
     * @return The price of the cToken in USD
     */
    function getPrice() private view returns (int256) {
        uint256 exchangeRateMantissa = cToken.exchangeRateStored();
        (, int256 price, , ,) = priceFeed.latestRoundData();

        (MathError mathErr, uint256 usdPrice) = mulUInt(exchangeRateMantissa, (uint256(price)));
        require(mathErr == MathError.NO_ERROR, "ERR_GET_USD_PRICE_MATH_ERROR");
        return int256(usdPrice) / (1 * 10 ** 18);
    }
}
