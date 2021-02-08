/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./FintrollerInterface.sol";
import "./FyTokenInterface.sol";
import "./external/balancer/BPoolInterface.sol";

/**
 * @title RedemptionPoolStorage
 * @author Hifi
 */
abstract contract RedemptionPoolStorage {
    /**
     * @notice The unique Fintroller associated with this contract.
     */
    FintrollerInterface public fintroller;

    /**
     * @notice The amount of the underlying asset available to be redeemed after maturation.
     */
    uint256 public totalUnderlyingSupply;

    /**
     * The unique fyToken associated with this Redemption Pool.
     */
    FyTokenInterface public fyToken;

    /**
     * @notice Indicator that this is a Redemption Pool contract, for inspection.
     */
    bool public constant isRedemptionPool = true;

    /**
     * @notice Indicator that calling the leveraged LP functionality is exclusive to RedemptionPool admin.
     */
    bool public isLeveragedLPAdminLocked = true;

    struct LeveragedLPPosition {
        uint256 totalUnderlying;
    }

    /**
     * @notice The Balancer pool for `underlying:fyToken` pair.
     */
    BPoolInterface public bPool;

    /**
     * @notice Bookkeeping to keep track of all leveraged LP providers and how much underlying tokens each has provided.
     */
    mapping(address => LeveragedLPPosition) public leveragedLPPositions;
}
