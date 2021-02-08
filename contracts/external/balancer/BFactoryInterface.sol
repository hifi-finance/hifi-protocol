/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

// Builds new BPools, logging their addresses and providing `isBPool(address) -> (bool)`

import "./BPoolInterface.sol";

/**
 * @title BFactoryInterface
 * @author Hifi
 */
interface BFactoryInterface {
    function isBPool(address b) external view returns (bool);

    function newBPool() external returns (BPoolInterface);

    function getBLabs() external view returns (address);

    function setBLabs(address b) external;

    function collect(BPoolInterface pool) external;
}
