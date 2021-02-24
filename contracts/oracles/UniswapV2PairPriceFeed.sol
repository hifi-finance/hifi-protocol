/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

/*
    Inspired by Alpha Finance's Fair Uniswap's LP Token Pricing
    https://blog.alphafinance.io/fair-lp-token-pricing
    https://github.com/AlphaFinanceLab/homora-v2/blob/master/contracts/oracle/UniswapV2Oracle.sol
*/

import "../external/uniswap/UniswapV2PairInterface.sol";
import "../external/uniswap/Math.sol";
import "@paulrberg/contracts/math/CarefulMath.sol";
import "../external/chainlink/AggregatorV3Interface.sol";

/**
 * @title UniswapV2PairPriceFeed
 * @author Hifi
 * @notice Chainlink-interfaced Uniswap LP token price feed.
 */
contract UniswapV2PairPriceFeed is AggregatorV3Interface, CarefulMath {
    string internal internalDescription;

    /**
     * @notice The Uniswap pair contract.
     */
    UniswapV2PairInterface public pair;

    /**
     * @notice USD-quoted Chainlink oracles for underlying paired assets.
     */
    AggregatorV3Interface[] public underlyingOracles;

    constructor(
        string memory description_,
        UniswapV2PairInterface pair_,
        AggregatorV3Interface[] memory underlyingOracles_
    ) {
        internalDescription = description_;
        pair = pair_;
        underlyingOracles = underlyingOracles_;
    }

    function decimals() external pure override returns (uint8) {
        return 8;
    }

    function description() external view override returns (string memory) {
        return internalDescription;
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 _roundId)
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
        require(_roundId == 0, "ERR_GET_ROUND_DATA_NO_HISTORIC_ROUNDS");
        return (0, getPriceInternal(), block.timestamp, block.timestamp, 0);
    }

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
        return (0, getPriceInternal(), block.timestamp, block.timestamp, 0);
    }

    struct GetPriceInternalLocalVars {
        MathError mathErr;
        uint256 divisor;
        uint256 r0;
        uint256 r1;
        uint256 k;
        uint256 sqrtK;
        int256 p0;
        int256 p1;
        uint256 p0p1;
        uint256 sqrtP0P1;
        uint256 sqrtR0R1sqrtP0P1;
        uint256 dividend;
        uint256 price;
    }

    /**
     * @notice Get the latest price of the LP token.
     * @return The price of the LP token quoted in USD (8 decimals).
     */
    function getPriceInternal() internal view returns (int256) {
        GetPriceInternalLocalVars memory vars;

        vars.divisor = pair.totalSupply();
        (vars.r0, vars.r1, ) = pair.getReserves();

        (, vars.p0, , , ) = underlyingOracles[0].latestRoundData();
        (, vars.p1, , , ) = underlyingOracles[1].latestRoundData();

        /* Will never overflow since types(uint112).max * types(uint112).max can fit into a uint256 */
        (, vars.k) = mulUInt(vars.r0, vars.r1);

        vars.sqrtK = Math.sqrt(vars.k);

        (vars.mathErr, vars.p0p1) = mulUInt(uint256(vars.p0), uint256(vars.p1));
        require(vars.mathErr == MathError.NO_ERROR, "ERR_LATEST_ROUND_DATA_MATH_ERROR");

        vars.sqrtP0P1 = Math.sqrt(vars.p0p1);

        (vars.mathErr, vars.sqrtR0R1sqrtP0P1) = mulUInt(vars.sqrtK, vars.sqrtP0P1);
        require(vars.mathErr == MathError.NO_ERROR, "ERR_LATEST_ROUND_DATA_MATH_ERROR");

        (vars.mathErr, vars.dividend) = mulUInt(vars.sqrtR0R1sqrtP0P1, 2);
        require(vars.mathErr == MathError.NO_ERROR, "ERR_LATEST_ROUND_DATA_MATH_ERROR");

        (vars.mathErr, vars.price) = divUInt(vars.dividend, vars.divisor);
        require(vars.mathErr == MathError.NO_ERROR, "ERR_LATEST_ROUND_DATA_MATH_ERROR");

        return int256(vars.price);
    }
}
