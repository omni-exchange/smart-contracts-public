// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

// Command implementations
import {Dispatcher} from "./base/Dispatcher.sol";
import {RouterParameters, RouterImmutables} from "./base/RouterImmutables.sol";
import {FluxSwapRouter} from "./modules/omni-exchange/flux/FluxSwapRouter.sol";
import {Commands} from "./libraries/Commands.sol";
import {Constants} from "./libraries/Constants.sol";
import {IUniversalRouter} from "./interfaces/IUniversalRouter.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Ownable, Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract UniversalRouter is RouterImmutables, IUniversalRouter, Dispatcher, Pausable, Ownable2Step {
    constructor(RouterParameters memory params)
        RouterImmutables(params)
        FluxSwapRouter(params.fluxVault, params.fluxClPoolManager, params.fluxBinPoolManager)
        Ownable(msg.sender)
    {}

    modifier checkDeadline(uint256 deadline) {
        if (block.timestamp > deadline) revert TransactionDeadlinePassed();
        _;
    }

    /// @notice To receive ETH from WETH
    receive() external payable {
        if (msg.sender != address(WETH9) && msg.sender != address(vault)) revert InvalidEthSender();
    }

    /// @inheritdoc IUniversalRouter
    function execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline)
        external
        payable
        checkDeadline(deadline)
    {
        execute(commands, inputs);
    }

    /// @inheritdoc Dispatcher
    function execute(bytes calldata commands, bytes[] calldata inputs)
        public
        payable
        override
        isNotLocked
        whenNotPaused
    {
        bool success;
        bytes memory output;
        uint256 numCommands = commands.length;
        if (inputs.length != numCommands) revert LengthMismatch();

        // loop through all given commands, execute them and pass along outputs as defined
        for (uint256 commandIndex = 0; commandIndex < numCommands; commandIndex++) {
            bytes1 command = commands[commandIndex];

            bytes calldata input = inputs[commandIndex];

            (success, output) = dispatch(command, input);

            if (!success && successRequired(command)) {
                revert ExecutionFailed({commandIndex: commandIndex, message: output});
            }
        }
    }

    function successRequired(bytes1 command) internal pure returns (bool) {
        return command & Commands.FLAG_ALLOW_REVERT == 0;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }
}
