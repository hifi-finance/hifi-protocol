// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.0;

library Precision {
    /// @notice Downscales the given normalized amount to have its actual decimals of precision.
    /// @param normalizedAmount The amount with 18 decimals of precision.
    /// @param precisionScalar The ratio between the native precision (18) and the denormalized precision.
    /// @return denormalizedAmount The amount with its actual decimals of precision.
    function denormalize(uint256 normalizedAmount, uint256 precisionScalar)
        internal
        pure
        returns (uint256 denormalizedAmount)
    {
        unchecked { denormalizedAmount = precisionScalar != 1 ? normalizedAmount / precisionScalar : normalizedAmount; }
    }

    /// @notice Upscales the given denormalized amount to normalized form, i.e. 18 decimals of precision.
    /// @param denormalizedAmount The amount with its actual decimals of precision.
    /// @param precisionScalar The ratio between the native precision (18) and the precision.
    /// @param normalizedAmount The amount with 18 decimals of precision.
    function normalize(uint256 denormalizedAmount, uint256 precisionScalar)
        internal
        pure
        returns (uint256 normalizedAmount)
    {
        normalizedAmount = precisionScalar != 1 ? denormalizedAmount * precisionScalar : denormalizedAmount;
    }
}
