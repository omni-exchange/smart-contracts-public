// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

/// @title Multicall interface forked from Multicall2
/// @notice Specifically tailored for the Omni interface
contract OmniInterfaceMulticall {
    struct Call {
        address target;     // Target address for the call
        uint256 gasLimit;   // Transaction gas limit
        bytes callData;     // Encoded transaction data
    }

    struct Result {
        bool success;       // Whether the call was successful
        uint256 gasUsed;    // Amount of gas used for the call
        bytes returnData;   // Encoded return data from the call
    }

    /// @notice Returns the current timestamp
    /// @return timestamp The current timestamp
    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }

    /// @notice Returns the native asset balance of a given address
    /// @param addr The address to check the balance of
    /// @return balance The native asset balance of the given address
    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }

    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param calls Array containing encoded function data for each of the calls to make
    /// @return blockNumber The block number at which the multicall was executed
    /// @return returnData Array containing results from each of the calls passed in via calls
    function multicall(Call[] memory calls) public returns (uint256 blockNumber, Result[] memory returnData) {
        blockNumber = block.number;
        returnData = new Result[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (address target, uint256 gasLimit, bytes memory callData) =
                (calls[i].target, calls[i].gasLimit, calls[i].callData);
            uint256 gasLeftBefore = gasleft();
            (bool success, bytes memory ret) = target.call{gas: gasLimit}(callData);
            uint256 gasUsed = gasLeftBefore - gasleft();
            returnData[i] = Result(success, gasUsed, ret);
        }
    }
}
