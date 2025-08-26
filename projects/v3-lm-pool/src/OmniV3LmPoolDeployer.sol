// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "@omni-exchange/v3-core/contracts/interfaces/IOmniV3Factory.sol";
import "@omni-exchange/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

import "./OmniV3LmPool.sol";

import "./interfaces/IMasterChefV3.sol";

/// @title OmniV3LmPoolDeployer
/// @notice Used by the MasterChefV3 contract to deploy a corresponding LmPool
/// when adding a new farming pool due to Solidity version incompatibilities 
contract OmniV3LmPoolDeployer {
    /// @notice Emitted when a new liquidity mining pool is deployed
    /// @param pool The address of the underlying OmniV3Pool contract
    /// @param lmPool The address of the deployed liquidity mining pool contract
    event NewLMPool(address indexed pool, address indexed lmPool);

    /// @notice Contains parameters for the initialization of a new liquidity mining pool
    struct Parameters {
        address pool;         // underlying OmniV3Pool contract address
        address masterChef;   // MasterChefV3 contract address
    }

    /// @notice Address of the MasterChefV3 contract
    address public immutable masterChef;

    /// @notice Parameters stored during the creation of a liquidity mining pool
    Parameters public parameters;

    /// @dev Prevents calling a function from anyone except the MasterChefV3 contract address
    modifier onlyMasterChef() {
        require(msg.sender == masterChef, "Not MC");
        _;
    }

    /// @dev Constructor
    constructor(address _masterChef) {
        masterChef = _masterChef;
    }

    /// @notice Deploys a liquidity mining pool for a OmniV3Pool
    /// @param pool The address of the underlying OmniV3Pool contract
    /// @return lmPool The address of the deployed liquidity mining pool contract
    function deploy(address pool) external onlyMasterChef returns (address lmPool) {
        parameters = Parameters({pool: pool, masterChef: masterChef});

        lmPool = address(new OmniV3LmPool{salt: keccak256(abi.encode(pool, masterChef, block.timestamp))}());

        delete parameters;

        // Set new LMPool for the Omni Exchange V3 pool
        IOmniV3Factory(INonfungiblePositionManager(IMasterChefV3(masterChef).nonfungiblePositionManager()).factory())
            .setLmPool(pool, lmPool);

        emit NewLMPool(pool, lmPool);
    }
}
