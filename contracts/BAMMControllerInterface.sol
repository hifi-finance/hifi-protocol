/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./BAMMControllerStorage.sol";

/**
 * @title BAMMControllerInterface
 * @author Hifi
 */
abstract contract BAMMControllerInterface is BAMMControllerStorage {
    /**
     * NON-CONSTANT FUNCTIONS
     */
    function setAdminLock(bool newLock) external virtual returns (bool);

    function injectLiquidity(uint256 underlyingAmount) external virtual returns (bool);

    function extractLiquidity(uint256 underlyingAmount) external virtual returns (bool);

    /**
     * EVENTS
     */
    event InjectLiquidity(address indexed account, uint256 underlyingAmount, uint256 fyTokenAmount);

    event ExtractLiquidity(address indexed account, uint256 underlyingAmount, uint256 fyTokenAmount);
}
