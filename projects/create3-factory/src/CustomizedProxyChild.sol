// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title Proxy child contract for supporting customized deployment logic
contract CustomizedProxyChild {

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         IMMUTABLES                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Address of the parent contract
    address public immutable parent;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ERRORS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    
    /// @notice Thrown when attempting to deploy a contract with an address other than the `parent`
    error NotFromParent();

    /// @notice ...
    error BackrunExecutionFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Constructor
    constructor() {
        parent = msg.sender;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     EXTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Deploys a contract
    /// @param creationCode Creation code (constructor) of the contract to be deployed
    /// @param creationFund Amount of native tokens (in wei) to be forwarded to the target contract's constructor
    /// @param backRunPayload Payload to be executed after contract creation
    /// @param backRunFund Amount of native tokens (in wei) to be forwarded for post-deploy execution
    function deploy(bytes memory creationCode, uint256 creationFund, bytes calldata backRunPayload, uint256 backRunFund)
        external
        payable
        returns (address addr)
    {
        // make sure only `Create3Factory` can deploy a contract in case of unauthorized deployment
        if (msg.sender != parent) {
            revert NotFromParent();
        }

        assembly {
            /// @dev create with creation code, deterministic addr since create(thisAddr=fixed, nonce=0)
            addr := create(creationFund, add(creationCode, 32), mload(creationCode))
        }

        if (backRunPayload.length != 0) {
            /// @dev This could be helpful when newly deployed contract
            /// needs to run some initialization logic for example owner update
            (bool success, bytes memory reason) = addr.call{value: backRunFund}(backRunPayload);
            if (!success) {
                // bubble up the revert reason from backrun if any
                if (reason.length > 0) {
                    assembly {
                        revert(add(reason, 32), mload(reason))
                    }
                }
                revert BackrunExecutionFailed();
            }
        }
    }
}
