// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;


/**
 * @title Uniswap Test Pair
 * @author Hifi
 * @dev Mock-up implementation of the Uniswap Pair contract (testing purposes only)
 */
contract UniswapTestPair {
  uint32 public blockTimestampLast;
  uint256 public _price0CumulativeLast;
  uint256 public _price1CumulativeLast;

  uint112 public reserve0;
  uint112 public reserve1;

  function price0CumulativeLast() external view returns (uint256) {
    return _price0CumulativeLast;
  }

  function price1CumulativeLast() external view returns (uint256) {
    return _price1CumulativeLast;
  }

  function getReserves() external view returns (
    uint112,
    uint112,
    uint32
  ) {
    return (
      reserve0,
      reserve1,
      blockTimestampLast
    );
  }
}
