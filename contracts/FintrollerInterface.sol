/// SPDX-License-Identifier: LPGL-3.0-or-later
pragma solidity ^0.8.0;

import "./FintrollerStorage.sol";
import "./FyTokenInterface.sol";
import "./oracles/ChainlinkOperatorInterface.sol";

abstract contract FintrollerInterface is FintrollerStorage {
    /// CONSTANT FUNCTIONS ///

    function getBond(FyTokenInterface fyToken) external view virtual returns (Bond memory);

    function getBorrowAllowed(FyTokenInterface fyToken) external view virtual returns (bool);

    function getBondCollateralizationRatio(FyTokenInterface fyToken) external view virtual returns (uint256);

    function getBondDebtCeiling(FyTokenInterface fyToken) external view virtual returns (uint256);

    function getBondLiquidationIncentive(FyTokenInterface fyToken) external view virtual returns (uint256);

    function getDepositCollateralAllowed(FyTokenInterface fyToken) external view virtual returns (bool);

    function getLiquidateBorrowAllowed(FyTokenInterface fyToken) external view virtual returns (bool);

    function getRedeemFyTokensAllowed(FyTokenInterface fyToken) external view virtual returns (bool);

    function getRepayBorrowAllowed(FyTokenInterface fyToken) external view virtual returns (bool);

    function getSupplyUnderlyingAllowed(FyTokenInterface fyToken) external view virtual returns (bool);

    function isBondListed(FyTokenInterface fyToken) external view virtual returns (bool);

    /// NON-CONSTANT FUNCTIONS ///

    function listBond(FyTokenInterface fyToken) external virtual returns (bool);

    function setBondCollateralizationRatio(FyTokenInterface fyToken, uint256 newCollateralizationRatioMantissa)
        external
        virtual
        returns (bool);

    function setBondDebtCeiling(FyTokenInterface fyToken, uint256 newDebtCeiling) external virtual returns (bool);

    function setBondLiquidationIncentive(FyTokenInterface fyToken, uint256 newLiquidationIncentive)
        external
        virtual
        returns (bool);

    function setBorrowAllowed(FyTokenInterface fyToken, bool state) external virtual returns (bool);

    function setDepositCollateralAllowed(FyTokenInterface fyToken, bool state) external virtual returns (bool);

    function setLiquidateBorrowAllowed(FyTokenInterface fyToken, bool state) external virtual returns (bool);

    function setOracle(ChainlinkOperatorInterface newOracle) external virtual returns (bool);

    function setRedeemFyTokensAllowed(FyTokenInterface fyToken, bool state) external virtual returns (bool);

    function setRepayBorrowAllowed(FyTokenInterface fyToken, bool state) external virtual returns (bool);

    function setSupplyUnderlyingAllowed(FyTokenInterface fyToken, bool state) external virtual returns (bool);

    /// EVENTS ///

    event ListBond(address indexed admin, FyTokenInterface indexed fyToken);

    event SetBorrowAllowed(address indexed admin, FyTokenInterface indexed fyToken, bool state);

    event SetBondCollateralizationRatio(
        address indexed admin,
        FyTokenInterface indexed fyToken,
        uint256 oldCollateralizationRatio,
        uint256 newCollateralizationRatio
    );

    event SetBondDebtCeiling(
        address indexed admin,
        FyTokenInterface indexed fyToken,
        uint256 oldDebtCeiling,
        uint256 newDebtCeiling
    );

    event SetBondLiquidationIncentive(
        address indexed admin,
        FyTokenInterface fyToken,
        uint256 oldLiquidationIncentive,
        uint256 newLiquidationIncentive
    );

    event SetDepositCollateralAllowed(address indexed admin, FyTokenInterface indexed fyToken, bool state);

    event SetLiquidateBorrowAllowed(address indexed admin, FyTokenInterface indexed fyToken, bool state);

    event SetRedeemFyTokensAllowed(address indexed admin, FyTokenInterface indexed fyToken, bool state);

    event SetRepayBorrowAllowed(address indexed admin, FyTokenInterface indexed fyToken, bool state);

    event SetOracle(address indexed admin, address oldOracle, address newOracle);

    event SetSupplyUnderlyingAllowed(address indexed admin, FyTokenInterface indexed fyToken, bool state);
}
