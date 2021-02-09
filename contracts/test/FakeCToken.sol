/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "../external/compound/CTokenInterface.sol";

/**
 * @title FakeCToken
 * @author Hifi
 * @dev Strictly for test purposes. Do not use in production.
 */
contract FakeCToken is CTokenInterface {
    function exchangeRateStored() external view override returns (uint) {
      return 0;
    }
}
