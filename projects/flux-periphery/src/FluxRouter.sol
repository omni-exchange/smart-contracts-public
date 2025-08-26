// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {IVault} from "flux-core/src/interfaces/IVault.sol";
import {ICLPoolManager} from "flux-core/src/pool-cl/interfaces/ICLPoolManager.sol";
import {IBinPoolManager} from "flux-core/src/pool-bin/interfaces/IBinPoolManager.sol";
import {Currency} from "flux-core/src/types/Currency.sol";
import {BipsLibrary} from "./libraries/BipsLibrary.sol";
import {CalldataDecoder} from "./libraries/CalldataDecoder.sol";
import {IFluxRouter} from "./interfaces/IFluxRouter.sol";
import {BaseActionsRouter} from "./base/BaseActionsRouter.sol";
import {DeltaResolver} from "./base/DeltaResolver.sol";
import {Actions} from "./libraries/Actions.sol";
import {CLCalldataDecoder} from "./pool-cl/libraries/CLCalldataDecoder.sol";
import {BinCalldataDecoder} from "./pool-bin/libraries/BinCalldataDecoder.sol";
import {CLRouterBase} from "./pool-cl/CLRouterBase.sol";
import {BinRouterBase} from "./pool-bin/BinRouterBase.sol";

/// @title FluxRouter
/// @notice Abstract contract that contains all internal logic needed for routing through Omni Exchange Flux pools
/// @dev the entry point to executing actions in this contract is calling `BaseActionsRouter._executeActions`
/// An inheriting contract should call _executeActions at the point that they wish actions to be executed
abstract contract FluxRouter is IFluxRouter, CLRouterBase, BinRouterBase, BaseActionsRouter {
    using BipsLibrary for uint256;
    using CalldataDecoder for bytes;
    using CLCalldataDecoder for bytes;
    using BinCalldataDecoder for bytes;

    constructor(IVault _vault, ICLPoolManager _clPoolManager, IBinPoolManager _binPoolManager)
        BaseActionsRouter(_vault)
        CLRouterBase(_clPoolManager)
        BinRouterBase(_binPoolManager)
    {}

    function _handleAction(uint256 action, bytes calldata params) internal override {
        // swap actions and payment actions in different blocks for gas efficiency
        if (action < Actions.SETTLE) {
            if (action == Actions.CL_SWAP_EXACT_IN) {
                IFluxRouter.CLSwapExactInputParams calldata swapParams = params.decodeCLSwapExactInParams();
                _swapExactInput(swapParams);
                return;
            } else if (action == Actions.CL_SWAP_EXACT_IN_SINGLE) {
                IFluxRouter.CLSwapExactInputSingleParams calldata swapParams =
                    params.decodeCLSwapExactInSingleParams();
                _swapExactInputSingle(swapParams);
                return;
            } else if (action == Actions.CL_SWAP_EXACT_OUT) {
                IFluxRouter.CLSwapExactOutputParams calldata swapParams = params.decodeCLSwapExactOutParams();
                _swapExactOutput(swapParams);
                return;
            } else if (action == Actions.CL_SWAP_EXACT_OUT_SINGLE) {
                IFluxRouter.CLSwapExactOutputSingleParams calldata swapParams =
                    params.decodeCLSwapExactOutSingleParams();
                _swapExactOutputSingle(swapParams);
                return;
            }
        } else if (action > Actions.BURN_6909) {
            if (action == Actions.BIN_SWAP_EXACT_IN) {
                IFluxRouter.BinSwapExactInputParams calldata swapParams = params.decodeBinSwapExactInParams();
                _swapExactInput(swapParams);
                return;
            } else if (action == Actions.BIN_SWAP_EXACT_IN_SINGLE) {
                IFluxRouter.BinSwapExactInputSingleParams calldata swapParams =
                    params.decodeBinSwapExactInSingleParams();
                _swapExactInputSingle(swapParams);
                return;
            } else if (action == Actions.BIN_SWAP_EXACT_OUT) {
                IFluxRouter.BinSwapExactOutputParams calldata swapParams = params.decodeBinSwapExactOutParams();
                _swapExactOutput(swapParams);
                return;
            } else if (action == Actions.BIN_SWAP_EXACT_OUT_SINGLE) {
                IFluxRouter.BinSwapExactOutputSingleParams calldata swapParams =
                    params.decodeBinSwapExactOutSingleParams();
                _swapExactOutputSingle(swapParams);
                return;
            }
        } else {
            if (action == Actions.SETTLE_ALL) {
                (Currency currency, uint256 maxAmount) = params.decodeCurrencyAndUint256();
                uint256 amount = _getFullDebt(currency);
                if (amount > maxAmount) revert TooMuchRequested(maxAmount, amount);
                _settle(currency, msgSender(), amount);
                return;
            } else if (action == Actions.TAKE_ALL) {
                (Currency currency, uint256 minAmount) = params.decodeCurrencyAndUint256();
                uint256 amount = _getFullCredit(currency);
                if (amount < minAmount) revert TooLittleReceived(minAmount, amount);
                _take(currency, msgSender(), amount);
                return;
            } else if (action == Actions.SETTLE) {
                (Currency currency, uint256 amount, bool payerIsUser) = params.decodeCurrencyUint256AndBool();
                _settle(currency, _mapPayer(payerIsUser), _mapSettleAmount(amount, currency));
                return;
            } else if (action == Actions.TAKE) {
                (Currency currency, address recipient, uint256 amount) = params.decodeCurrencyAddressAndUint256();
                _take(currency, _mapRecipient(recipient), _mapTakeAmount(amount, currency));
                return;
            } else if (action == Actions.TAKE_PORTION) {
                (Currency currency, address recipient, uint256 bips) = params.decodeCurrencyAddressAndUint256();
                _take(currency, _mapRecipient(recipient), _getFullCredit(currency).calculatePortion(bips));
                return;
            }
        }
        revert UnsupportedAction(action);
    }
}
