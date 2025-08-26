// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./pool/IOmniV3PoolImmutables.sol";
import "./pool/IOmniV3PoolState.sol";
import "./pool/IOmniV3PoolDerivedState.sol";
import "./pool/IOmniV3PoolActions.sol";
import "./pool/IOmniV3PoolOwnerActions.sol";
import "./pool/IOmniV3PoolEvents.sol";

/// @title The interface for an Omni Exchange V3 Pool
/// @notice An Omni Exchange V3 pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IOmniV3Pool is
    IOmniV3PoolImmutables,
    IOmniV3PoolState,
    IOmniV3PoolDerivedState,
    IOmniV3PoolActions,
    IOmniV3PoolOwnerActions,
    IOmniV3PoolEvents
{}
