/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "@paulrberg/contracts/token/erc20/Erc20.sol";

import "./libraries/IUniswapV2Factory.sol";
import "./libraries/IUniswapV2Pair.sol";
import "./libraries/FixedPoint.sol";
import "./libraries/SafeMath.sol";
import "./libraries/UniswapV2Library.sol";
import "./libraries/UniswapV2OracleLibrary.sol";

import "../../external/chainlink/AggregatorV3Interface.sol";


/**
 * @title Uniswap Price Feed
 * @author Hifi
 * @notice A Uniswap TWAP Oracle mixed with a Chainlink price feed
 * @dev Based on the oracle example provided by Uniswap and extending the Chainlink price aggregator
 * https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/examples/ExampleSlidingWindowOracle.sol
 */
contract UniswapPriceFeed is AggregatorV3Interface {
  using FixedPoint for *;
  using SafeMath for uint256;

  struct Observation {
    uint256 timestamp;
    uint256 price0Cumulative;
    uint256 price1Cumulative;
  }

  string internal internalDescription;

  address public immutable factory;
  uint256 public immutable windowSize;
  uint8 public immutable granularity;
  uint256 public immutable periodSize;

  address public WETH;
  address public targetToken;
  uint256 public targetTokenDecimals;
  address public pair;

  AggregatorV3Interface public priceFeed;

  Observation[] public observations;

  event PriceUpdated();

  /**
   * @param _factory The address of the Uniswap factory
   * @param _windowSize The size of the time window
   * @param _granularity The granularity of the window
   * @param _WETH The address of the WETH token
   * @param _targetToken The address of the target token
   * @param _priceFeed The address of the WETH/USD price feed
   */
  constructor(
    string memory _description,
    address _factory,
    uint256 _windowSize,
    uint8 _granularity,
    address _WETH,
    address _targetToken,
    address _pair,
    address _priceFeed
  ) {
    require(_granularity > 1, "Invalid granularity");
    require(
      (periodSize = _windowSize / _granularity) * _granularity == _windowSize,
      "Window not divisible"
    );

    internalDescription = _description;
    factory = _factory;
    windowSize = _windowSize;
    granularity = _granularity;
    WETH = _WETH;
    targetToken = _targetToken;
    Erc20 token = Erc20(_targetToken);
    targetTokenDecimals = token.decimals();
    // pair = UniswapV2Library.pairFor(_factory, _targetToken, _WETH);
    pair = _pair;
    priceFeed = AggregatorV3Interface(_priceFeed);
  }

  /**
   * @notice Returns the amount of decimals used in the price
   * @return The number of decimals of the price
   */
  function decimals() external pure override returns (uint8) {
    return 8;
  }

  /**
   * @notice Returns the description of the price feed
   * @return The description of the price feed
   */
  function description() external view override returns (string memory) {
    return internalDescription;
  }

  /**
   * @notice Returns the version of the price feed
   * @return The version of the price feed
   */
  function version() external pure override returns (uint256) {
    return 1;
  }

  /**
   * @notice Returns the observation index for a specific timestamp
   * @param timestamp The timestamp to look for
   * @return The index
   */
  function observationIndexOf(uint256 timestamp) public view returns (uint8) {
    uint256 epochPeriod = timestamp / periodSize;
    return uint8(epochPeriod % granularity);
  }

  /**
   * @notice Returns the first observation of the current window
   * @return The first observation of the window
   */
  function getFirstObservationInWindow() private view returns (
    Observation storage
  ) {
    uint8 observationIndex = observationIndexOf(block.timestamp);
    uint8 firstObservationIndex = (observationIndex + 1) % granularity;
    return observations[firstObservationIndex];
  }

  /**
   * @notice Saves the current cumulative prices into the oracle
   */
  function update() external {
    for (uint256 i = observations.length; i < granularity; i += 1) {
      observations.push();
    }

    uint8 observationIndex = observationIndexOf(block.timestamp);
    Observation storage observation = observations[observationIndex];

    uint256 timeElapsed = block.timestamp - observation.timestamp;

    if (timeElapsed > periodSize) {
      (uint256 price0Cumulative, uint256 price1Cumulative, ) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
      observation.timestamp = block.timestamp;
      observation.price0Cumulative = price0Cumulative;
      observation.price1Cumulative = price1Cumulative;

      emit PriceUpdated();
    }
  }

  /**
   * @notice Computes the amount out from cumulative prices and an amount in
   * @param priceCumulativeStart The first price of the period
   * @param priceCumulativeEnd The last price of the period
   * @param timeElapsed The time elapsed between the two prices
   * @param amountIn The amount of tokens in
   * @return The amount of tokens out
   */
  function computeAmountOut(
    uint256 priceCumulativeStart,
    uint256 priceCumulativeEnd,
    uint256 timeElapsed,
    uint256 amountIn
  ) private pure returns (
    uint256
  ) {
    FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
      uint224(
        (priceCumulativeEnd - priceCumulativeStart) / timeElapsed
      )
    );

    return priceAverage.mul(amountIn).decode144();
  }

  /**
   * @notice Returns the latest price of the target token in ETH
   * @return The price of the target token in ETH
   */
  function getLatestETHPrice() public view returns (uint256) {
    Observation storage firstObservation = getFirstObservationInWindow();

    uint256 timeElapsed = block.timestamp - firstObservation.timestamp;

    require(timeElapsed <= windowSize, "Missing historical data");
    require(timeElapsed >= windowSize - periodSize * 2, "Unexpected time elapsed");

    (uint256 price0Cumulative, uint256 price1Cumulative, ) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
    (address token0, ) = UniswapV2Library.sortTokens(targetToken, WETH);

    uint256 amountIn = 1 * 10 ** targetTokenDecimals;

    if (token0 != targetToken) {
      return computeAmountOut(firstObservation.price0Cumulative, price0Cumulative, timeElapsed, amountIn);
    } else {
      return computeAmountOut(firstObservation.price1Cumulative, price1Cumulative, timeElapsed, amountIn);
    }
  }

  /**
   * @notice Returns the latest price of the target token in USD
   * @return The price of the target token in USD
   */
  function getLatestPrice() public view returns (uint256) {
    uint256 priceInETH = getLatestETHPrice();
    (, int256 price, , , ) = priceFeed.latestRoundData();
    return priceInETH.mul(uint256(price)) / 10 ** 18;
  }

  /**
   * @notice Returns the latest price of the target token in USD
   * @dev This function is compliant to the AggregatorV3Interface
   * @param _roundId This parameter is ignored
   * @return roundId Not used here
   * @return answer The price of the target token in USD
   * @return startedAt Not used here
   * @return updatedAt Not used here
   * @return answeredInRound Not used here
   */
  function getRoundData(uint80 _roundId) external override view returns (
    uint80 roundId,
    int256 answer,
    uint256 startedAt,
    uint256 updatedAt,
    uint80 answeredInRound
  ) {
    return (
      0,
      int256(getLatestPrice()),
      0,
      0,
      0
    );
  }

  /**
   * @notice Returns the latest price of the target token in USD
   * @dev This function is compliant to the AggregatorV3Interface
   * @return roundId Not used here
   * @return answer The price of the target token in USD
   * @return startedAt Not used here
   * @return updatedAt Not used here
   * @return answeredInRound Not used here
   */
  function latestRoundData() external override view returns (
    uint80 roundId,
    int256 answer,
    uint256 startedAt,
    uint256 updatedAt,
    uint80 answeredInRound
  ) {
    return (
      0,
      int256(getLatestPrice()),
      0,
      0,
      0
    );
  }
}
