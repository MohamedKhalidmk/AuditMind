
pragma solidity ^0.8.0;

import {SafeCast} from "./SafeCast.sol";
import {TickBitmap} from "./TickBitmap.sol";
import {Position} from "./Position.sol";
import {UnsafeMath} from "./UnsafeMath.sol";
import {FixedPoint128} from "./FixedPoint128.sol";
import {TickMath} from "./TickMath.sol";
import {SqrtPriceMath} from "./SqrtPriceMath.sol";
import {SwapMath} from "./SwapMath.sol";
import {BalanceDelta, toBalanceDelta, BalanceDeltaLibrary} from "../types/BalanceDelta.sol";
import {Slot0} from "../types/Slot0.sol";
import {ProtocolFeeLibrary} from "./ProtocolFeeLibrary.sol";
import {LiquidityMath} from "./LiquidityMath.sol";
import {LPFeeLibrary} from "./LPFeeLibrary.sol";
import {CustomRevert} from "./CustomRevert.sol";


library Pool {
    using SafeCast for *;
    using TickBitmap for mapping(int16 => uint256);
    using Position for mapping(bytes32 => Position.State);
    using Position for Position.State;
    using Pool for State;
    using ProtocolFeeLibrary for *;
    using LPFeeLibrary for uint24;
    using CustomRevert for bytes4;

    
    
    
    error TicksMisordered(int24 tickLower, int24 tickUpper);

    
    
    error TickLowerOutOfBounds(int24 tickLower);

    
    
    error TickUpperOutOfBounds(int24 tickUpper);

    
    error TickLiquidityOverflow(int24 tick);

    
    error PoolAlreadyInitialized();

    
    error PoolNotInitialized();

    
    
    
    error PriceLimitAlreadyExceeded(uint160 sqrtPriceCurrentX96, uint160 sqrtPriceLimitX96);

    
    
    error PriceLimitOutOfBounds(uint160 sqrtPriceLimitX96);

    
    error NoLiquidityToReceiveFees();

    
    error InvalidFeeForExactOut();

    
    struct TickInfo {
        
        uint128 liquidityGross;
        
        int128 liquidityNet;
        
        
        uint256 feeGrowthOutside0X128;
        uint256 feeGrowthOutside1X128;
    }

    
    
    
    
    struct State {
        Slot0 slot0;
        uint256 feeGrowthGlobal0X128;
        uint256 feeGrowthGlobal1X128;
        uint128 liquidity;
        mapping(int24 tick => TickInfo) ticks;
        mapping(int16 wordPos => uint256) tickBitmap;
        mapping(bytes32 positionKey => Position.State) positions;
    }

    
    function checkTicks(int24 tickLower, int24 tickUpper) private pure {
        if (tickLower >= tickUpper) TicksMisordered.selector.revertWith(tickLower, tickUpper);
        if (tickLower < TickMath.MIN_TICK) TickLowerOutOfBounds.selector.revertWith(tickLower);
        if (tickUpper > TickMath.MAX_TICK) TickUpperOutOfBounds.selector.revertWith(tickUpper);
    }

    function initialize(State storage self, uint160 sqrtPriceX96, uint24 lpFee) internal returns (int24 tick) {
        if (self.slot0.sqrtPriceX96() != 0) PoolAlreadyInitialized.selector.revertWith();

        tick = TickMath.getTickAtSqrtPrice(sqrtPriceX96);

        
        self.slot0 = Slot0.wrap(bytes32(0)).setSqrtPriceX96(sqrtPriceX96).setTick(tick).setLpFee(lpFee);
    }

    function setProtocolFee(State storage self, uint24 protocolFee) internal {
        self.checkPoolInitialized();
        self.slot0 = self.slot0.setProtocolFee(protocolFee);
    }

    
    function setLPFee(State storage self, uint24 lpFee) internal {
        self.checkPoolInitialized();
        self.slot0 = self.slot0.setLpFee(lpFee);
    }

    struct ModifyLiquidityParams {
        
        address owner;
        
        int24 tickLower;
        int24 tickUpper;
        
        int128 liquidityDelta;
        
        int24 tickSpacing;
        
        bytes32 salt;
    }

    struct ModifyLiquidityState {
        bool flippedLower;
        uint128 liquidityGrossAfterLower;
        bool flippedUpper;
        uint128 liquidityGrossAfterUpper;
    }

    
    
    
    
    
    function modifyLiquidity(State storage self, ModifyLiquidityParams memory params)
        internal
        returns (BalanceDelta delta, BalanceDelta feeDelta)
    {
        int128 liquidityDelta = params.liquidityDelta;
        int24 tickLower = params.tickLower;
        int24 tickUpper = params.tickUpper;
        checkTicks(tickLower, tickUpper);

        {
            ModifyLiquidityState memory state;

            
            if (liquidityDelta != 0) {
                (state.flippedLower, state.liquidityGrossAfterLower) =
                    updateTick(self, tickLower, liquidityDelta, false);
                (state.flippedUpper, state.liquidityGrossAfterUpper) = updateTick(self, tickUpper, liquidityDelta, true);

                
                if (liquidityDelta >= 0) {
                    uint128 maxLiquidityPerTick = tickSpacingToMaxLiquidityPerTick(params.tickSpacing);
                    if (state.liquidityGrossAfterLower > maxLiquidityPerTick) {
                        TickLiquidityOverflow.selector.revertWith(tickLower);
                    }
                    if (state.liquidityGrossAfterUpper > maxLiquidityPerTick) {
                        TickLiquidityOverflow.selector.revertWith(tickUpper);
                    }
                }

                if (state.flippedLower) {
                    self.tickBitmap.flipTick(tickLower, params.tickSpacing);
                }
                if (state.flippedUpper) {
                    self.tickBitmap.flipTick(tickUpper, params.tickSpacing);
                }
            }

            {
                (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) =
                    getFeeGrowthInside(self, tickLower, tickUpper);

                Position.State storage position = self.positions.get(params.owner, tickLower, tickUpper, params.salt);
                (uint256 feesOwed0, uint256 feesOwed1) =
                    position.update(liquidityDelta, feeGrowthInside0X128, feeGrowthInside1X128);

                
                feeDelta = toBalanceDelta(feesOwed0.toInt128(), feesOwed1.toInt128());
            }

            
            if (liquidityDelta < 0) {
                if (state.flippedLower) {
                    clearTick(self, tickLower);
                }
                if (state.flippedUpper) {
                    clearTick(self, tickUpper);
                }
            }
        }

        if (liquidityDelta != 0) {
            Slot0 _slot0 = self.slot0;
            (int24 tick, uint160 sqrtPriceX96) = (_slot0.tick(), _slot0.sqrtPriceX96());
            if (tick < tickLower) {
                
                
                delta = toBalanceDelta(
                    SqrtPriceMath.getAmount0Delta(
                        TickMath.getSqrtPriceAtTick(tickLower), TickMath.getSqrtPriceAtTick(tickUpper), liquidityDelta
                    ).toInt128(),
                    0
                );
            } else if (tick < tickUpper) {
                delta = toBalanceDelta(
                    SqrtPriceMath.getAmount0Delta(sqrtPriceX96, TickMath.getSqrtPriceAtTick(tickUpper), liquidityDelta)
                        .toInt128(),
                    SqrtPriceMath.getAmount1Delta(TickMath.getSqrtPriceAtTick(tickLower), sqrtPriceX96, liquidityDelta)
                        .toInt128()
                );

                self.liquidity = LiquidityMath.addDelta(self.liquidity, liquidityDelta);
            } else {
                
                
                delta = toBalanceDelta(
                    0,
                    SqrtPriceMath.getAmount1Delta(
                        TickMath.getSqrtPriceAtTick(tickLower), TickMath.getSqrtPriceAtTick(tickUpper), liquidityDelta
                    ).toInt128()
                );
            }
        }
    }

    
    struct SwapResult {
        
        uint160 sqrtPriceX96;
        
        int24 tick;
        
        uint128 liquidity;
    }

    struct StepComputations {
        
        uint160 sqrtPriceStartX96;
        
        int24 tickNext;
        
        bool initialized;
        
        uint160 sqrtPriceNextX96;
        
        uint256 amountIn;
        
        uint256 amountOut;
        
        uint256 feeAmount;
        
        uint256 feeGrowthGlobalX128;
    }

    struct SwapParams {
        int256 amountSpecified;
        int24 tickSpacing;
        bool zeroForOne;
        uint160 sqrtPriceLimitX96;
        uint24 lpFeeOverride;
    }

    
    
    function swap(State storage self, SwapParams memory params)
        internal
        returns (BalanceDelta swapDelta, uint256 amountToProtocol, uint24 swapFee, SwapResult memory result)
    {
        Slot0 slot0Start = self.slot0;
        bool zeroForOne = params.zeroForOne;

        uint256 protocolFee =
            zeroForOne ? slot0Start.protocolFee().getZeroForOneFee() : slot0Start.protocolFee().getOneForZeroFee();

        
        int256 amountSpecifiedRemaining = params.amountSpecified;
        
        int256 amountCalculated = 0;
        
        result.sqrtPriceX96 = slot0Start.sqrtPriceX96();
        
        result.tick = slot0Start.tick();
        
        result.liquidity = self.liquidity;

        
        
        {
            uint24 lpFee = params.lpFeeOverride.isOverride()
                ? params.lpFeeOverride.removeOverrideFlagAndValidate()
                : slot0Start.lpFee();

            swapFee = protocolFee == 0 ? lpFee : uint16(protocolFee).calculateSwapFee(lpFee);
        }

        
        if (swapFee >= SwapMath.MAX_SWAP_FEE) {
            
            if (params.amountSpecified > 0) {
                InvalidFeeForExactOut.selector.revertWith();
            }
        }

        
        
        if (params.amountSpecified == 0) return (BalanceDeltaLibrary.ZERO_DELTA, 0, swapFee, result);

        if (zeroForOne) {
            if (params.sqrtPriceLimitX96 >= slot0Start.sqrtPriceX96()) {
                PriceLimitAlreadyExceeded.selector.revertWith(slot0Start.sqrtPriceX96(), params.sqrtPriceLimitX96);
            }
            
            
            if (params.sqrtPriceLimitX96 <= TickMath.MIN_SQRT_PRICE) {
                PriceLimitOutOfBounds.selector.revertWith(params.sqrtPriceLimitX96);
            }
        } else {
            if (params.sqrtPriceLimitX96 <= slot0Start.sqrtPriceX96()) {
                PriceLimitAlreadyExceeded.selector.revertWith(slot0Start.sqrtPriceX96(), params.sqrtPriceLimitX96);
            }
            if (params.sqrtPriceLimitX96 >= TickMath.MAX_SQRT_PRICE) {
                PriceLimitOutOfBounds.selector.revertWith(params.sqrtPriceLimitX96);
            }
        }

        StepComputations memory step;
        step.feeGrowthGlobalX128 = zeroForOne ? self.feeGrowthGlobal0X128 : self.feeGrowthGlobal1X128;

        
        while (!(amountSpecifiedRemaining == 0 || result.sqrtPriceX96 == params.sqrtPriceLimitX96)) {
            step.sqrtPriceStartX96 = result.sqrtPriceX96;

            (step.tickNext, step.initialized) =
                self.tickBitmap.nextInitializedTickWithinOneWord(result.tick, params.tickSpacing, zeroForOne);

            
            if (step.tickNext <= TickMath.MIN_TICK) {
                step.tickNext = TickMath.MIN_TICK;
            }
            if (step.tickNext >= TickMath.MAX_TICK) {
                step.tickNext = TickMath.MAX_TICK;
            }

            
            step.sqrtPriceNextX96 = TickMath.getSqrtPriceAtTick(step.tickNext);

            
            (result.sqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) = SwapMath.computeSwapStep(
                result.sqrtPriceX96,
                SwapMath.getSqrtPriceTarget(zeroForOne, step.sqrtPriceNextX96, params.sqrtPriceLimitX96),
                result.liquidity,
                amountSpecifiedRemaining,
                swapFee
            );

            
            if (params.amountSpecified > 0) {
                unchecked {
                    amountSpecifiedRemaining -= step.amountOut.toInt256();
                }
                amountCalculated -= (step.amountIn + step.feeAmount).toInt256();
            } else {
                
                unchecked {
                    amountSpecifiedRemaining += (step.amountIn + step.feeAmount).toInt256();
                }
                amountCalculated += step.amountOut.toInt256();
            }

            
            if (protocolFee > 0) {
                unchecked {
                    
                    
                    
                    
                    uint256 delta = (swapFee == protocolFee)
                        ? step.feeAmount 
                        : (step.amountIn + step.feeAmount) * protocolFee / ProtocolFeeLibrary.PIPS_DENOMINATOR;
                    
                    step.feeAmount -= delta;
                    amountToProtocol += delta;
                }
            }

            
            if (result.liquidity > 0) {
                unchecked {
                    
                    step.feeGrowthGlobalX128 +=
                        UnsafeMath.simpleMulDiv(step.feeAmount, FixedPoint128.Q128, result.liquidity);
                }
            }

            
            
            
            
            if (result.sqrtPriceX96 == step.sqrtPriceNextX96) {
                
                if (step.initialized) {
                    (uint256 feeGrowthGlobal0X128, uint256 feeGrowthGlobal1X128) = zeroForOne
                        ? (step.feeGrowthGlobalX128, self.feeGrowthGlobal1X128)
                        : (self.feeGrowthGlobal0X128, step.feeGrowthGlobalX128);
                    int128 liquidityNet =
                        Pool.crossTick(self, step.tickNext, feeGrowthGlobal0X128, feeGrowthGlobal1X128);
                    
                    
                    unchecked {
                        if (zeroForOne) liquidityNet = -liquidityNet;
                    }

                    result.liquidity = LiquidityMath.addDelta(result.liquidity, liquidityNet);
                }

                unchecked {
                    result.tick = zeroForOne ? step.tickNext - 1 : step.tickNext;
                }
            } else if (result.sqrtPriceX96 != step.sqrtPriceStartX96) {
                
                result.tick = TickMath.getTickAtSqrtPrice(result.sqrtPriceX96);
            }
        }

        self.slot0 = slot0Start.setTick(result.tick).setSqrtPriceX96(result.sqrtPriceX96);

        
        if (self.liquidity != result.liquidity) self.liquidity = result.liquidity;

        
        if (!zeroForOne) {
            self.feeGrowthGlobal1X128 = step.feeGrowthGlobalX128;
        } else {
            self.feeGrowthGlobal0X128 = step.feeGrowthGlobalX128;
        }

        unchecked {
            
            if (zeroForOne != (params.amountSpecified < 0)) {
                swapDelta = toBalanceDelta(
                    amountCalculated.toInt128(), (params.amountSpecified - amountSpecifiedRemaining).toInt128()
                );
            } else {
                swapDelta = toBalanceDelta(
                    (params.amountSpecified - amountSpecifiedRemaining).toInt128(), amountCalculated.toInt128()
                );
            }
        }
    }

    
    function donate(State storage state, uint256 amount0, uint256 amount1) internal returns (BalanceDelta delta) {
        uint128 liquidity = state.liquidity;
        if (liquidity == 0) NoLiquidityToReceiveFees.selector.revertWith();
        unchecked {
            
            delta = toBalanceDelta(-(amount0.toInt128()), -(amount1.toInt128()));
            
            if (amount0 > 0) {
                state.feeGrowthGlobal0X128 += UnsafeMath.simpleMulDiv(amount0, FixedPoint128.Q128, liquidity);
            }
            if (amount1 > 0) {
                state.feeGrowthGlobal1X128 += UnsafeMath.simpleMulDiv(amount1, FixedPoint128.Q128, liquidity);
            }
        }
    }

    
    
    
    
    
    
    function getFeeGrowthInside(State storage self, int24 tickLower, int24 tickUpper)
        internal
        view
        returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128)
    {
        TickInfo storage lower = self.ticks[tickLower];
        TickInfo storage upper = self.ticks[tickUpper];
        int24 tickCurrent = self.slot0.tick();

        unchecked {
            if (tickCurrent < tickLower) {
                feeGrowthInside0X128 = lower.feeGrowthOutside0X128 - upper.feeGrowthOutside0X128;
                feeGrowthInside1X128 = lower.feeGrowthOutside1X128 - upper.feeGrowthOutside1X128;
            } else if (tickCurrent >= tickUpper) {
                feeGrowthInside0X128 = upper.feeGrowthOutside0X128 - lower.feeGrowthOutside0X128;
                feeGrowthInside1X128 = upper.feeGrowthOutside1X128 - lower.feeGrowthOutside1X128;
            } else {
                feeGrowthInside0X128 =
                    self.feeGrowthGlobal0X128 - lower.feeGrowthOutside0X128 - upper.feeGrowthOutside0X128;
                feeGrowthInside1X128 =
                    self.feeGrowthGlobal1X128 - lower.feeGrowthOutside1X128 - upper.feeGrowthOutside1X128;
            }
        }
    }

    
    
    
    
    
    
    
    function updateTick(State storage self, int24 tick, int128 liquidityDelta, bool upper)
        internal
        returns (bool flipped, uint128 liquidityGrossAfter)
    {
        TickInfo storage info = self.ticks[tick];

        uint128 liquidityGrossBefore = info.liquidityGross;
        int128 liquidityNetBefore = info.liquidityNet;

        liquidityGrossAfter = LiquidityMath.addDelta(liquidityGrossBefore, liquidityDelta);

        flipped = (liquidityGrossAfter == 0) != (liquidityGrossBefore == 0);

        if (liquidityGrossBefore == 0) {
            
            if (tick <= self.slot0.tick()) {
                info.feeGrowthOutside0X128 = self.feeGrowthGlobal0X128;
                info.feeGrowthOutside1X128 = self.feeGrowthGlobal1X128;
            }
        }

        
        
        int128 liquidityNet = upper ? liquidityNetBefore - liquidityDelta : liquidityNetBefore + liquidityDelta;
        assembly ("memory-safe") {
            
            
            sstore(
                info.slot,
                
                or(
                    
                    and(liquidityGrossAfter, 0xffffffffffffffffffffffffffffffff),
                    
                    shl(128, liquidityNet)
                )
            )
        }
    }

    
    
    
    
    
    function tickSpacingToMaxLiquidityPerTick(int24 tickSpacing) internal pure returns (uint128 result) {
        
        
        
        
        
        
        int24 MAX_TICK = TickMath.MAX_TICK;
        int24 MIN_TICK = TickMath.MIN_TICK;
        
        assembly ("memory-safe") {
            tickSpacing := signextend(2, tickSpacing)
            let minTick := sub(sdiv(MIN_TICK, tickSpacing), slt(smod(MIN_TICK, tickSpacing), 0))
            let maxTick := sdiv(MAX_TICK, tickSpacing)
            let numTicks := add(sub(maxTick, minTick), 1)
            result := div(sub(shl(128, 1), 1), numTicks)
        }
    }

    
    function checkPoolInitialized(State storage self) internal view {
        if (self.slot0.sqrtPriceX96() == 0) PoolNotInitialized.selector.revertWith();
    }

    
    
    
    function clearTick(State storage self, int24 tick) internal {
        delete self.ticks[tick];
    }

    
    
    
    
    
    
    function crossTick(State storage self, int24 tick, uint256 feeGrowthGlobal0X128, uint256 feeGrowthGlobal1X128)
        internal
        returns (int128 liquidityNet)
    {
        unchecked {
            TickInfo storage info = self.ticks[tick];
            info.feeGrowthOutside0X128 = feeGrowthGlobal0X128 - info.feeGrowthOutside0X128;
            info.feeGrowthOutside1X128 = feeGrowthGlobal1X128 - info.feeGrowthOutside1X128;
            liquidityNet = info.liquidityNet;
        }
    }
}
