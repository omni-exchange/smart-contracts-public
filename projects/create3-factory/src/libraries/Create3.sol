// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {CustomizedProxyChild} from "../CustomizedProxyChild.sol";

/// @title A library for deploying contracts EIP-3171 style
/// @dev Referenced from https://github.com/0xsequence/create3/blob/master/contracts/Create3.sol
/// Updated PROXY_CHILD_BYTECODE to support customized deployment logic
/// @author Agustin Aguilar <aa@horizon.io>
library Create3 {

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Creation code bytes value of the `CustomizedProxyChild` contract
    bytes internal constant PROXY_CHILD_BYTECODE = type(CustomizedProxyChild).creationCode;

    /// @dev Keccak256 hashed bytes32 value of the `CustomizedProxyChild` contract
    bytes32 internal constant KECCAK256_PROXY_CHILD_BYTECODE = keccak256(PROXY_CHILD_BYTECODE);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ERRORS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Thrown when the `CREATE2` proxy contract is a zero address
    error ErrorCreatingProxy();
    
    /// @notice Thrown when the pre-calculated address doesn't match the target contract address
    error ErrorCreatingContract();

    /// @notice Thrown when the pre-calculated address already exists
    error TargetAlreadyExists();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Creates a new contract with given `_creationCode` and `_salt`
    /// @param _salt Salt of the contract creation, resulting address will be derived from this value only
    /// @param _creationCode Creation code (constructor) of the contract to be deployed
    /// @param _creationFund  Amount of native tokens (in wei) to be forwarded to the target contract's constructor
    /// @param _afterDeploymentExecutionPayload Payload to be executed after contract creation
    /// @param _afterDeploymentExecutionFund Amount of native tokens (in wei) to be forwarded for post-deploy execution
    /// @return addr of the deployed contract, reverts on error
    function create3(
        bytes32 _salt,
        bytes memory _creationCode,
        uint256 _creationFund,
        bytes calldata _afterDeploymentExecutionPayload,
        uint256 _afterDeploymentExecutionFund
    ) internal returns (address addr) {
        // creation code
        bytes memory proxyCreationCode = PROXY_CHILD_BYTECODE;

        // get the target's final address
        address preCalculatedAddr = addressOf(_salt);
        if (codeSize(preCalculatedAddr) != 0) {
            revert TargetAlreadyExists();
        }

        // create `CREATE2` proxy
        address proxy;
        assembly {
            proxy := create2(0, add(proxyCreationCode, 32), mload(proxyCreationCode), _salt)
        }

        if (proxy == address(0)) {
            revert ErrorCreatingProxy();
        }

        // call proxy with final init code to deploy target contract
        addr = CustomizedProxyChild(proxy).deploy{value: _creationFund + _afterDeploymentExecutionFund}(
            _creationCode, _creationFund, _afterDeploymentExecutionPayload, _afterDeploymentExecutionFund
        );

        if (preCalculatedAddr != addr) {
            revert ErrorCreatingContract();
        }
    }

    /// @notice Returns the size of the code on a given address
    /// @param _addr Address that may or may not contain code
    /// @return size of the code on the given `_addr`
    function codeSize(address _addr) internal view returns (uint256 size) {
        assembly {
            size := extcodesize(_addr)
        }
    }

    /// @notice Computes the resulting address of a contract deployed using address(this) and the given `_salt`
    /// @dev The address creation formula is: 
    /// keccak256(rlp([keccak256(0xff ++ address(this) ++ _salt ++ keccak256(childBytecode))[12:], 0x01]))
    /// @param _salt Salt of the contract creation, resulting address will be derived from this value only
    /// @return addr of the deployed contract, reverts on error
    function addressOf(bytes32 _salt) internal view returns (address) {
        address proxy = address(
            uint160(uint256(keccak256(abi.encodePacked(hex"ff", address(this), _salt, KECCAK256_PROXY_CHILD_BYTECODE))))
        );

        return address(uint160(uint256(keccak256(abi.encodePacked(hex"d694", proxy, hex"01")))));
    }
}
