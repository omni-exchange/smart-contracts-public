// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @notice Library to define different mixed quoter actions.
library MixedQuoterActions {
    // ExactInput actions
    uint256 constant V2_EXACT_INPUT_SINGLE = 0x00;
    uint256 constant V3_EXACT_INPUT_SINGLE = 0x01;

    uint256 constant FLUX_CL_EXACT_INPUT_SINGLE = 0x02;
    uint256 constant FLUX_BIN_EXACT_INPUT_SINGLE = 0x03;
}
