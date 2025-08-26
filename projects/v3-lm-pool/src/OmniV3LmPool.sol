// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "@omni-exchange/v3-core/contracts/libraries/LowGasSafeMath.sol";
import "@omni-exchange/v3-core/contracts/libraries/SafeCast.sol";
import "@omni-exchange/v3-core/contracts/libraries/FullMath.sol";
import "@omni-exchange/v3-core/contracts/libraries/FixedPoint128.sol";
import "@omni-exchange/v3-core/contracts/interfaces/IOmniV3Pool.sol";

import "./libraries/LmTick.sol";

import "./interfaces/IOmniV3LmPool.sol";
import "./interfaces/IMasterChefV3.sol";
import "./interfaces/IOmniV3LmPoolDeveloper.sol";

/// @title Omni Exchange V3 Liquidity Mining Pool
/// @notice Tracks liquidity mining rewards for MasterChefV3 campaigns
contract OmniV3LmPool is IOmniV3LmPool {
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
    using LmTick for mapping(int24 => LmTick.Info);

    /// @notice The precision for reward calculations
    uint256 public constant REWARD_PRECISION = 1e12;

    /// @notice Address of the underlying OmniV3Pool contract
    IOmniV3Pool public immutable pool;

    /// @notice Address of the MasterChefV3 contract
    IMasterChefV3 public immutable masterChef;

    /// @notice The global liquidity mining reward growth per unit of liquidity for the entire life of the pool
    uint256 public rewardGrowthGlobalX128;

    /// @notice The currently in range liquidity available to the liquidity mining pool
    uint128 public lmLiquidity;

    /// @notice The timestamp of the latest reward accumulation event
    uint32 public lastRewardTimestamp;

    /// @notice Contains information about individual ticks
    mapping(int24 => LmTick.Info) public lmTicks;

    /// @dev Prevents calling a function from anyone except the underlying pool contract address
    modifier onlyPool() {
        require(msg.sender == address(pool), "NOT_POOL");
        _;
    }

    /// @dev Prevents calling a function from anyone except the MasterChefV3 contract address
    modifier onlyMasterChef() {
        require(msg.sender == address(masterChef), "NOT_MASTER_CHEF");
        _;
    }

    /// @dev Prevents calling a function from anyone except the MasterChefV3 or the underlying pool contract addresses
    modifier onlyPoolOrMasterChef() {
        require(msg.sender == address(pool) || msg.sender == address(masterChef), "NOT_POOL_OR_MASTER_CHEF");
        _;
    }

    /// @dev Constructor
    constructor() {
        (address poolAddress, address masterChefAddress) = IOmniV3LmPoolDeveloper(msg.sender).parameters();
        pool = IOmniV3Pool(poolAddress);
        masterChef = IMasterChefV3(masterChefAddress);
        lastRewardTimestamp = uint32(block.timestamp);
    }

    /// @inheritdoc IOmniV3LmPool
    function accumulateReward(uint32 currTimestamp) external override onlyPoolOrMasterChef {
        if (currTimestamp <= lastRewardTimestamp) {
            return;
        }

        if (lmLiquidity != 0) {
            (uint256 rewardPerSecond, uint256 endTime) = masterChef.getLatestPeriodInfo(address(pool));

            uint32 endTimestamp = uint32(endTime);
            uint32 duration;
            if (endTimestamp > currTimestamp) {
                duration = currTimestamp - lastRewardTimestamp;
            } else if (endTimestamp > lastRewardTimestamp) {
                duration = endTimestamp - lastRewardTimestamp;
            }

            if (duration != 0) {
                rewardGrowthGlobalX128 += FullMath.mulDiv(duration, FullMath.mulDiv(rewardPerSecond, FixedPoint128.Q128, REWARD_PRECISION), lmLiquidity);
            }
        }

        lastRewardTimestamp = currTimestamp;
    }

    /// @inheritdoc IOmniV3LmPool
    function crossLmTick(int24 tick, bool zeroForOne) external override onlyPool {
        if (lmTicks[tick].liquidityGross == 0) {
            return;
        }

        int128 lmLiquidityNet = lmTicks.cross(tick, rewardGrowthGlobalX128);

        if (zeroForOne) {
            lmLiquidityNet = -lmLiquidityNet;
        }

        lmLiquidity = LiquidityMath.addDelta(lmLiquidity, lmLiquidityNet);
    }

    /// @notice Updates the liquidity mining pool's information
    /// @param tickLower The lower tick boundary
    /// @param tickUpper The upper tick boundary
    /// @param liquidityDelta The change in liquidity
    function updatePosition(int24 tickLower, int24 tickUpper, int128 liquidityDelta) external onlyMasterChef {
        (, int24 tick, , , , ,) = pool.slot0();
        uint128 maxLiquidityPerTick = pool.maxLiquidityPerTick();
        uint256 _rewardGrowthGlobalX128 = rewardGrowthGlobalX128;

        bool flippedLower;
        bool flippedUpper;
        if (liquidityDelta != 0) {
            flippedLower = lmTicks.update(
                tickLower,
                tick,
                liquidityDelta,
                _rewardGrowthGlobalX128,
                false,
                maxLiquidityPerTick
            );
            flippedUpper = lmTicks.update(
                tickUpper,
                tick,
                liquidityDelta,
                _rewardGrowthGlobalX128,
                true,
                maxLiquidityPerTick
            );
        }

        if (tick >= tickLower && tick < tickUpper) {
            lmLiquidity = LiquidityMath.addDelta(lmLiquidity, liquidityDelta);
        }

        if (liquidityDelta < 0) {
            if (flippedLower) {
                lmTicks.clear(tickLower);
            }
            if (flippedUpper) {
                lmTicks.clear(tickUpper);
            }
        }
    }

    /// @notice Returns the all-time reward growth, per unit of liquidity inside a specified tick range
    /// @param tickLower The lower tick boundary
    /// @param tickUpper The upper tick boundary
    /// @return rewardGrowthInsideX128 The all-time reward growth, per unit of liquidity inside the specified tick range
    function getRewardGrowthInside(int24 tickLower, int24 tickUpper) external view returns (uint256 rewardGrowthInsideX128) {
        (, int24 tick, , , , ,) = pool.slot0();
        return lmTicks.getRewardGrowthInside(tickLower, tickUpper, tick, rewardGrowthGlobalX128);
    }
}
