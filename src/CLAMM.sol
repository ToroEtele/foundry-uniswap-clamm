// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20} from "./interfaces/IERC20.sol";
import {SafeCast} from "./lib/SafeCast.sol";
import {Position} from "./lib/Position.sol";
import {TickMath} from "./lib/TickMath.sol";
import {Tick} from "./lib/Tick.sol";

contract CLAMM {
    using SafeCast for uint256;

    address public immutable token0;
    address public immutable token1;
    // Fee represents some kind of percentage on swaps
    uint24 public immutable fee;

    int public immutable tickSpacing;
    uint128 public immutable maxLiquidityPerTick;

    struct Slot0 {
        uint160 sqrtPriceX96;
        int24 tick;
        bool unlocked; // this is used to prevent reentrancy
    }

    Slot0 public slot0;
    mapping(bytes32 => Position.Info) public positions;

    // @dev this is used to prevent reentrancy
    modifier lock() {
        require(!slot0.unlocked, "locked");
        slot0.unlocked = true;
        _;
        slot0.unlocked = false;
    }

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

    struct ModifyPositionParams {
        address owner;
        int24 tickLower;
        int24 tickUpper;
        int128 liquidityDelta;
    }

    function _modifyPosition(
        ModifyPositionParams memory params
    )
        private
        returns (Position.Info storage position, int256 amount0, int256 amount1)
    {
        return (positions[bytes32(0)], 0, 0);
    }

    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external lock returns (uint256 amount0, uint256 amount1) {
        require(amount > 0, "amount = 0");

        (, int256 amount0Int, int256 amount1Int) = _modifyPosition(
            ModifyPositionParams({
                owner: recipient,
                tickLower: tickLower,
                tickUpper: tickUpper,
                // 0 < amount <= max int128 = 2**127 - 1
                liquidityDelta: int256(uint256(amount)).toInt128()
            })
        );

        amount0 = uint256(amount0Int);
        amount1 = uint256(amount1Int);

        if (amount0 > 0) {
            IERC20(token0).transferFrom(msg.sender, address(this), amount0);
        }
        if (amount1 > 0) {
            IERC20(token1).transferFrom(msg.sender, address(this), amount1);
        }
    }
}
