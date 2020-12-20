pragma solidity ^0.7.0;

/**
 * @dev `AggregatorV3Interface` by Chainlink
 * @dev Source: https://docs.chain.link/docs/price-feeds-api-reference
 */
interface IAggregatorV3 {
    /*
     * @dev Get the number of decimals present in the response value
     */
    function decimals() external view returns (uint8);

    /*
     * @dev Get the description of the underlying aggregator that the proxy points to
     */
    function description() external view returns (string memory);

    /*
     * @dev Get the version representing the type of aggregator the proxy points to
     */
    function version() external view returns (uint256);

    /**
     * @dev Get data from a specific round
     * @notice It raises "No data present" if there is no data to report
     * @notice Consumers are encouraged to check they're receiving fresh data
     * by inspecting the updatedAt and answeredInRound return values.
     * @notice The round id is made up of the aggregator's round ID with the phase ID
     * in the two highest order bytes (it ensures round IDs get larger as time moves forward)
     * @param roundId The round ID
     * @return roundId The round ID
     * @return answer The price
     * @return startedAt Timestamp of when the round started
     * (Only some AggregatorV3Interface implementations return meaningful values)
     * @return updatedAt Timestamp of when the round was updated (computed)
     * @return answeredInRound The round ID of the round in which the answer was computed
     * (Only some AggregatorV3Interface implementations return meaningful values)
     */
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    /**
     * @dev Get data from the last round
     * Should raise "No data present" if there is no data to report
     * @return roundId The round ID
     * @return answer The price
     * @return startedAt Timestamp of when the round started
     * @return updatedAt Timestamp of when the round was updated
     * @return answeredInRound The round ID of the round in which the answer was computed
     */
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}
