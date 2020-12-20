/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "../oracles/ChainlinkOperatorInterface.sol";

/**
 * @title SimplePriceOracleView
 * @author Mainframe
 * @dev Strictly for testing purposes. Do not use in production.
 */
contract SimplePriceOracleView {
    uint256 public daiPrice;
    uint256 public wethPrice;

    constructor() {
        daiPrice = 100000000; /* $1 */
        wethPrice = 10000000000; /* $100 */
    }

    function setDaiPrice(uint256 newDaiPrice) external {
        daiPrice = newDaiPrice;
    }

    function setWethPrice(uint256 newWethPrice) external {
        wethPrice = newWethPrice;
    }

    /**
     * @notice Prices are returned in the format that the Chainlink USD price feeds use, i.e. 8 decimals of precision.
     * @dev See https://docs.chain.link/docs/using-chainlink-reference-contracts
     */
    function price(string memory symbol) external view returns (uint256) {
        if (areStringsEqual(symbol, "ETH")) {
            return wethPrice;
        } else if (areStringsEqual(symbol, "DAI")) {
            return daiPrice;
        } else {
            /* Everything else is worth $0 */
            return 0;
        }
    }

    function areStringsEqual(string memory a, string memory b) public pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}
