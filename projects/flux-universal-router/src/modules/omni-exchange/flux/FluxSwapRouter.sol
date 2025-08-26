// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {Permit2Payments} from "../../Permit2Payments.sol";
import {FluxRouter} from "flux-periphery/src/FluxRouter.sol";
import {IVault} from "flux-core/src/interfaces/IVault.sol";
import {ICLPoolManager} from "flux-core/src/pool-cl/interfaces/ICLPoolManager.sol";
import {IBinPoolManager} from "flux-core/src/pool-bin/interfaces/IBinPoolManager.sol";
import {Currency} from "flux-core/src/types/Currency.sol";

/// @title Router for Omni Exchange Flux Trades
abstract contract FluxSwapRouter is FluxRouter, Permit2Payments {
    constructor(address _vault, address _clPoolManager, address _binPoolManager)
        FluxRouter(IVault(_vault), ICLPoolManager(_clPoolManager), IBinPoolManager(_binPoolManager))
    {}

    function _pay(Currency token, address payer, uint256 amount) internal override {
        payOrPermit2Transfer(Currency.unwrap(token), payer, address(vault), amount);
    }
}
