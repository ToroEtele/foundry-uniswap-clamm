// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20} from "./interfaces/IERC20.sol";
import {SafeCast} from "./lib/SafeCast.sol";
import {Position} from "./lib/Position.sol";
import {TickMath} from "./lib/TickMath.sol";
import {Tick} from "./lib/Tick.sol";

function checkTicks(int24 tickLower, int24 tickUpper) pure {
    require(tickLower < tickUpper);
    require(TickMath.MIN_TICK <= tickLower);
    require(tickUpper <= TickMath.MAX_TICK);
}

contract CLAMM {
    using SafeCast for uint256;
    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;

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

    function _updatePosition(
        address owner,
        int24 tickLower,
        int24 tickUpper,
        int128 liquidityDelta,
        int24 tick
    ) private returns (Position.Info storage position) {
        position = positions.get(owner, tickLower, tickUpper);

        // TODO: Calculate fees
        uint256 _feeGrowthGlobal0X128 = 0;
        uint256 _feeGrowthGlobal1X128 = 0;

        // TODO: Calculate fees
        position.update(liquidityDelta, 0, 0);
    }

    function _modifyPosition(
        ModifyPositionParams memory params
    )
        private
        returns (Position.Info storage position, int256 amount0, int256 amount1)
    {
        checkTicks(params.tickLower, params.tickUpper);

        Slot0 memory _slot0 = slot0;

        position = _updatePosition(
            params.owner,
            params.tickLower,
            params.tickUpper,
            params.liquidityDelta,
            _slot0.tick
        );

        return (positions[bytes32(0)], 0, 0);
    }

    /**
     *
     * @param recipient The address of the liquidity provider who will receive the minted liquidity tokens.
     * @param tickLower The lower price tick of the tick range to which liquidity is added.
     * @param tickUpper The upper price tick of the tick range to which liquidity is added.
     * @param amount Amount of liquidity to add to the pool
     * @return amount0
     * @return amount1
     * @dev When you add liquidity to the pool, this function gets called
     */
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
                liquidityDelta: int128(int256(uint256(amount)))
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
