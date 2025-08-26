//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for the `Create3Factory` contract
interface ICreate3Factory {
    /// @notice Thrown when attempting to call a whitelist restricted function with a non-whitelisted address
    error NotWhitelisted();

    /// @notice Thrown when the `creationCodeHash` value does not equal the keccak256 hashed `creationCode` bytes value
    error CreationCodeHashMismatch();

    /// @notice Thrown when the sum of `creationFund` and `afterDeploymentExecutionFund` don't match the `msg.value`
    error FundsAmountMismatch();

    /// @notice Checks the whitelist status of a given user
    /// @param user Address of the user
    /// @return bool Boolean flag indicating whether the user is whitelisted or not
    function isUserWhitelisted(address user) external view returns (bool);

    /// @notice Deploys a contract using `CREATE3`
    /// @dev As long as the same salt is used, the contract will be deployed at the same address on other chain
    /// @param salt Salt of the contract creation, resulting address will be derived from this value only
    /// @param creationCode Creation code (constructor + args) of the contract to be deployed, this value doesn't affect the resulting address
    /// @param creationCodeHash Hash of the creation code, it can be used to verify the creation code
    /// @param creationFund In WEI of ETH to be forwarded to target contract constructor
    /// @param afterDeploymentExecutionPayload Payload to be executed after contract creation
    /// @param afterDeploymentExecutionFund In WEI of ETH to be forwarded to when executing after deployment initialization
    /// @return deployed of the deployed contract, reverts on error
    function deploy(
        bytes32 salt,
        bytes memory creationCode,
        bytes32 creationCodeHash,
        uint256 creationFund,
        bytes calldata afterDeploymentExecutionPayload,
        uint256 afterDeploymentExecutionFund
    ) external payable returns (address deployed);

    /// @notice Computes the `create3` address based on a `salt` value
    /// @param salt Salt value
    /// @return address Address of the contract
    function computeAddress(bytes32 salt) external view returns (address);

    /// @notice Sets the deployment whitelist status for a user
    /// @param user Address of the user
    /// @param isWhiteList Whitelist status of the user
    function setWhitelistUser(address user, bool isWhiteList) external;
}
