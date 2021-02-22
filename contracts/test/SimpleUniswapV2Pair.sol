/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "../external/uniswap/UniswapV2PairInterface.sol";

/**
 * @title SimplePriceFeed
 * @author Hifi
 */
contract SimpleUniswapV2Pair is UniswapV2PairInterface {
    uint256 internal totalSupplyInternal;
    uint112 internal reserve0;
    uint112 internal reserve1;
    uint256 internal blockTimestampLast;

    function totalSupply() external view override returns (uint256) {
        return totalSupplyInternal;
    }

    function getReserves()
        external
        view
        override
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = uint32(block.timestamp);
    }

    function update(
        uint112 _reserve0,
        uint112 _reserve1,
        uint256 _totalSupply
    ) public {
        totalSupplyInternal = _totalSupply;
        reserve0 = _reserve0;
        reserve1 = _reserve1;
        blockTimestampLast = block.timestamp;
    }
}
