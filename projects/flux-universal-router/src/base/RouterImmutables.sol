// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";
import {IV3NonfungiblePositionManager} from
    "flux-periphery/src/interfaces/external/IV3NonfungiblePositionManager.sol";
import {IPositionManager} from "flux-periphery/src/interfaces/IPositionManager.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IWETH9} from "flux-periphery/src/interfaces/external/IWETH9.sol";

struct RouterParameters {
    // Payment parameters
    address permit2;
    address weth9;
    // Omni Exchange V2 & V3 swapping parameters
    address v2Factory;
    address v3Factory;
    address v3Deployer;
    bytes32 v2InitCodeHash;
    bytes32 v3InitCodeHash;
    // Omni Exchange Flux swapping parameters, param not in this contract as stored in fluxSwapRouter
    address fluxVault;
    address fluxClPoolManager;
    address fluxBinPoolManager;
    // Omni Exchange V3 -> Flux migration parameters
    address v3NFTPositionManager;
    address fluxClPositionManager;
    address fluxBinPositionManager;
}

/// @title Router Immutable Storage contract
/// @notice Used along with the `RouterParameters` struct for ease of cross-chain deployment
contract RouterImmutables {
    /// @dev WETH9 address
    IWETH9 internal immutable WETH9;

    /// @dev Permit2 address
    IPermit2 internal immutable PERMIT2;

    /// @dev The address of the OmniV2Factory contract
    address internal immutable OMNI_EXCHANGE_V2_FACTORY;

    /// @dev The Omni Exchange V2 pair initcodehash
    bytes32 internal immutable OMNI_EXCHANGE_V2_PAIR_INIT_CODE_HASH;

    /// @dev The address of the OmniV3Factory contract
    address internal immutable OMNI_EXCHANGE_V3_FACTORY;

    /// @dev The Omni Exchange V3 pool initcodehash
    bytes32 internal immutable OMNI_EXCHANGE_V3_POOL_INIT_CODE_HASH;

    /// @dev The address of the Omni Exchange V3 pool deployer contract
    address internal immutable OMNI_EXCHANGE_V3_DEPLOYER;

    /// @dev The address of the Omni Exchange V3 nonfungible position manager contract
    IV3NonfungiblePositionManager public immutable V3_POSITION_MANAGER;

    /// @dev Flux CLPositionManager address
    IPositionManager public immutable FLUX_CL_POSITION_MANAGER;

    /// @dev Flux BinPositionManager address
    IPositionManager public immutable FLUX_BIN_POSITION_MANAGER;

    constructor(RouterParameters memory params) {
        PERMIT2 = IPermit2(params.permit2);
        WETH9 = IWETH9(params.weth9);
        OMNI_EXCHANGE_V2_FACTORY = params.v2Factory;
        OMNI_EXCHANGE_V2_PAIR_INIT_CODE_HASH = params.v2InitCodeHash;
        OMNI_EXCHANGE_V3_FACTORY = params.v3Factory;
        OMNI_EXCHANGE_V3_POOL_INIT_CODE_HASH = params.v3InitCodeHash;
        OMNI_EXCHANGE_V3_DEPLOYER = params.v3Deployer;
        V3_POSITION_MANAGER = IV3NonfungiblePositionManager(params.v3NFTPositionManager);
        FLUX_CL_POSITION_MANAGER = IPositionManager(params.fluxClPositionManager);
        FLUX_BIN_POSITION_MANAGER = IPositionManager(params.fluxBinPositionManager);
    }
}
