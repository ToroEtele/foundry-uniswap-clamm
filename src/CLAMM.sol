// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Tick} from "./lib/Tick.sol";

contract CLAMM {
    address public immutable token0;
    address public immutable token1;
    // @dev Fee represents some kind of percentage on swaps
    uint24 public immutable fee;
    int public immutable tickSpacing;
    uint128 public immutable maxLiquidityPerTick;

    constructor(
        address _token0,
        address _token1,
        uint24 _fee,
        int24 _tickSpacing
    ) {
        token0 = _token0;
        token1 = _token1;
        fee = _fee;
        tickSpacing = _tickSpacing;

        maxLiquidityPerTick = Tick.tickSpacingToMaxLiquidityPerTick(
            _tickSpacing
        );
    }
}
