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
 */
contract UniswapV2PairPriceFeed is AggregatorV3Interface, CarefulMath {
    string internal internalDescription;

    // UniswapV2Pair
    UniswapV2PairInterface public pair;

    // ETH-quoted Chainlink oracles
    AggregatorV3Interface public token0Oracle;
    AggregatorV3Interface public token1Oracle;

    constructor(
        UniswapV2PairInterface pair_,
        AggregatorV3Interface token0Oracle_,
        AggregatorV3Interface token1Oracle_,
        string memory description_
    ) {
        pair = pair_;
        token0Oracle = token0Oracle_;
        token1Oracle = token1Oracle_;
        internalDescription = description_;
    }

    function decimals() external pure override returns (uint8) {
        return 18;
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
        return this.latestRoundData();
    }

    struct LatestRoundDataLocalVars {
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
        LatestRoundDataLocalVars memory vars;

        vars.divisor = UniswapV2PairInterface(pair).totalSupply();
        (vars.r0, vars.r1, ) = UniswapV2PairInterface(pair).getReserves();

        (, vars.p0, , , ) = token0Oracle.latestRoundData();
        (, vars.p1, , , ) = token1Oracle.latestRoundData();

        (vars.mathErr, vars.k) = mulUInt(vars.r0, vars.r1);
        require(vars.mathErr == MathError.NO_ERROR, "ERR_LATEST_ROUND_DATA_MATH_ERROR");

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

        return (0, int256(vars.price), 0, block.timestamp, 0);
    }
}
