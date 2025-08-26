// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title IOmniV3LmPoolDeveloper
/// @notice Interface contract used during the creation of the OmniV3LmPool contract
interface IOmniV3LmPoolDeveloper {
    /// @notice Returns the parameters created in the OmniV3LmPoolDeployer contract during deployment
    /// @return pool The address of the underlying OmniV3Pool contract
    /// @return masterChef The address of the MasterChefV3 contract
    function parameters() external view returns (address pool, address masterChef);
}
