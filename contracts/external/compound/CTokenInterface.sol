/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

/**
 * @title CTokenInterface
 * @author Hifi
 * @dev Forked from https://github.com/compound-finance/compound-protocol/blob/master/contracts/CTokenInterfaces.sol
 */
interface CTokenInterface {
    function exchangeRateStored() external view returns (uint);
}
