/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../external/chainlink/IAggregatorV3.sol";
import "@paulrberg/contracts/token/erc20/Erc20Interface.sol";

/**
 * @title ChainlinkOperatorInterface
 * @author Mainframe
 */
interface ChainlinkOperatorInterface {
    struct Feed {
        address id; // Chainlink price feed contract address
        address asset; // contract address of token that price feed is tracking value of
        bool disabled; // false by default
    }

    /**
     * @notice Get the official price for a symbol.
     * @param symbol The symbol to fetch the price of.
     * @return Price denominated in USD, with 8 decimals.
     */
    function price(string memory symbol) external view returns (uint256);

    /**
     * @notice Add a new Chainlink price feed.
     * @param feed The Chainlink price feed contract.
     * @param asset The contract of asset to add price feed of.
     */
    function addFeed(IAggregatorV3 feed, Erc20Interface asset) external;

    /**
     * @notice Get the official feed for a symbol.
     * @param symbol The symbol to return the price feed data of.
     * @return Price feed data.
     */
    function getFeed(string memory symbol) external view returns (Feed memory);

    /**
     * @notice Disable a Chainlink price feed.
     * @param symbol The symbol of asset to disable price feed of.
     */
    function disableFeed(string memory symbol) external;

    /**
     * @notice Disable a Chainlink price feed.
     * @param symbol The symbol of asset to enable price feed of.
     */
    function enableFeed(string memory symbol) external;
}
