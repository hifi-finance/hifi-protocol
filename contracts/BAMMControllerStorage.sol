/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./FyTokenInterface.sol";
import "./external/balancer/BPoolInterface.sol";

/**
 * @title BAMMControllerStorage
 * @author Hifi
 */
abstract contract BAMMControllerStorage {
    /**
     * The unique fyToken associated with this Balancer AMM Controller.
     */
    FyTokenInterface public fyToken;

    /**
     * @notice Indicator that this is a Balancer AMM Controller contract, for inspection.
     */
    bool public constant isBAMMController = true;

    /**
     * @notice Indicator that calling LP functionality is exclusive to BAMMController admin.
     */
    bool public isAdminLocked = true;

    struct Position {
        uint256 totalUnderlying;
    }

    /**
     * @notice The Balancer pool for `underlying:fyToken` pair.
     */
    BPoolInterface public bPool;

    /**
     * @notice Bookkeeping to keep track of all liquidity providers and how much underlying tokens each has provided.
     */
    mapping(address => Position) public positions;
}
