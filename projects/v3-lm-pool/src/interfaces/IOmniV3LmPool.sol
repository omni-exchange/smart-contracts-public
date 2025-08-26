// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title IOmniV3LmPool
/// @notice Minimal interface for the OmniV3LmPool contract
interface IOmniV3LmPool {
  /// @notice Accumulates rewards for the liquidity mining pool
  /// @param currTimestamp The current timestamp
  function accumulateReward(uint32 currTimestamp) external;

  /// @notice Crosses a tick in the liquidity mining pool and updates the in-range liquidity
  /// @param tick The tick to cross
  /// @param zeroForOne The direction to cross the tick
  function crossLmTick(int24 tick, bool zeroForOne) external;
}
