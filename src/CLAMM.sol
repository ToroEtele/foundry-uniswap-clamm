// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Tick} from "./lib/Tick.sol";
import {TickMath} from "./lib/TickMath.sol";

contract CLAMM {
    address public immutable token0;
    address public immutable token1;
    // @dev Fee represents some kind of percentage on swaps
    uint24 public immutable fee;

    int public immutable tickSpacing;
    uint128 public immutable maxLiquidityPerTick;

    struct Slot0 {
        uint160 sqrtPriceX96;
        int24 tick;
        bool unlocked; //@dev this is used to prevent reentrancy
    }

    Slot0 public slot0;

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

    // @notice this funtion is called after this contract is deployed, to set the initial price
    function initialize(uint160 sqrtPriceX96) external {
        require(slot0.sqrtPriceX96 == 0, "ALREADY_INITIALIZED");
        slot0.sqrtPriceX96 = sqrtPriceX96;

        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

        slot0 = Slot0({sqrtPriceX96: sqrtPriceX96, tick: tick, unlocked: true});
    }
}
