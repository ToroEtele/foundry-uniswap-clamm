// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./TickMath.sol";

library Tick {
    /**
     * @param tickSpacing The tick spacing of the pool
     * @return maxLiquidityPerTick The maximum amount of liquidity that can be in a tick
     * @notice The ticks are moving in an interval like (-500, 500),
     * tick spacing gives us a number with which tick is growing/decrease inside the interval,
     * so we can calculate how much tick is in the interval.
     */
    function tickSpacingToMaxLiquidityPerTick(
        int24 tickSpacing
    ) internal pure returns (uint128) {
        // @dev This ensures that minTick and maxTick are multiples of tickSpacing
        int24 minTick = (TickMath.MIN_TICK / tickSpacing) * tickSpacing;
        int24 maxTick = (TickMath.MAX_TICK / tickSpacing) * tickSpacing;
        // @dev How much ticks are in the interval? ex. (-500,, 500) with tickSpacing 2 has 501 ticks
        uint24 numTicks = uint24((maxTick - minTick) / tickSpacing) + 1;
        // @dev How much liquidity can be in each tick? Type of the variable liquidity is uint128
        return type(uint128).max / numTicks;
    }
}
