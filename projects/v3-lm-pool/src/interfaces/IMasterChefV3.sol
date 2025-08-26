// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

/// @title IMasterChefV3
/// @notice Minimal interface for the MasterChefV3 contract
interface IMasterChefV3 {
    /// @notice Returns the NonfungiblePositionManager contract address
    /// @return address The NonfungiblePositionManager contract address
    function nonfungiblePositionManager() external view returns (address);

    /// @notice Returns the position information of a specified V3 position staked in the MasterChefV3 contract
    /// @param _v3Pool The address of the V3 pool
    /// @return omniPerSecond The amount of OMNI tokens distributed per second
    /// @return endTime The timestamp of the end of the liquidity mining period
    function getLatestPeriodInfo(address _v3Pool) external view returns (uint256 omniPerSecond, uint256 endTime);
}
