/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./SimpleUniswapV2Pair.sol";
import "../external/uniswap/UniswapV2PairInterface.sol";
import "../external/chainlink/AggregatorV3Interface.sol";

/**
 * @title SimplePriceFeed
 * @author Hifi
 */
contract SimpleUniswapV2PairPriceFeed is SimpleUniswapV2Pair {
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
        UniswapV2PairInterface pair_,
        AggregatorV3Interface[] memory underlyingOracles_,
        string memory description_
    ) {
        pair = pair_;
        underlyingOracles = underlyingOracles_;
        internalDescription = description_;
    }
}
