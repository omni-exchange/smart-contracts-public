// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {Create3} from "./libraries/Create3.sol";
import {ICreate3Factory} from "./interfaces/ICreate3Factory.sol";

/// @title Factory contract for deploying contracts in a deterministic fashion using `CREATE3`
/// @dev Ensure this contract is deployed on multiple chains with the same address
contract Create3Factory is ICreate3Factory, Ownable2Step, ReentrancyGuard {
    
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          MAPPINGS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Only whitelisted user can interact with create2Factory
    mapping(address user => bool isWhitelisted) public isUserWhitelisted;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Emitted when a user's whitelist status has been updated
    /// @param user Address of the user whose whitelist status was updated
    /// @param isWhitelist Boolean flag indicating the updated whitelist status of the user
    event WhitelistUpdated(address indexed user, bool isWhitelist);

    /// @notice Emitted when a contract has been deployed
    /// @param deployed Address of the deployed contract
    /// @param salt Salt value used to deploy the contract with
    /// @param creationCodeHash Creation code hash of the deployed contract
    event ContractDeployed(address indexed deployed, bytes32 salt, bytes32 creationCodeHash);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Functions marked by this modifier can only be called by a whitelisted address
    modifier onlyWhitelisted() {
        if (!isUserWhitelisted[msg.sender]) revert NotWhitelisted();
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Constructor
    constructor() Ownable(msg.sender) {
        isUserWhitelisted[msg.sender] = true;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PUBLIC FUNCTIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @inheritdoc ICreate3Factory
    function computeAddress(bytes32 salt) public view returns (address) {
        return Create3.addressOf(salt);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  EXTERNAL ADMIN FUNCTIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @inheritdoc ICreate3Factory
    function deploy(
        bytes32 salt,
        bytes memory creationCode,
        bytes32 creationCodeHash,
        uint256 creationFund,
        bytes calldata afterDeploymentExecutionPayload,
        uint256 afterDeploymentExecutionFund
    ) external payable onlyWhitelisted nonReentrant returns (address deployed) {
        if (creationCodeHash != keccak256(creationCode)) {
            revert CreationCodeHashMismatch();
        }

        if (creationFund + afterDeploymentExecutionFund != msg.value) {
            revert FundsAmountMismatch();
        }

        deployed = Create3.create3(
            salt, creationCode, creationFund, afterDeploymentExecutionPayload, afterDeploymentExecutionFund
        );

        emit ContractDeployed(deployed, salt, creationCodeHash);
    }

    /// @inheritdoc ICreate3Factory
    function setWhitelistUser(address user, bool isWhiteList) external onlyOwner {
        isUserWhitelisted[user] = isWhiteList;

        emit WhitelistUpdated(user, isWhiteList);
    }
}
