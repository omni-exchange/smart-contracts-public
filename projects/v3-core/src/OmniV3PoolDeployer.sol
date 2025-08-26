// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "./OmniV3Pool.sol";

import "./interfaces/IOmniV3PoolDeployer.sol";

/// @title Omni Exchange V3 Liquidity Pool Deployer
/// @notice Used by the OmniV3Factory contract to deploy liquidity pools
contract OmniV3PoolDeployer is IOmniV3PoolDeployer {
    // parameters to be used in constructing the pool
    struct Parameters {
        address factory;     // address of the OmniV3Factory
        address token0;      // first token of the pool by address sort order
        address token1;      // second token of the pool by address sort order
        uint24 fee;          // fee collected upon every swap in the pool, denominated in hundredths of a bip
        int24 tickSpacing;   // minimum number of ticks between initialized ticks
    }

    /// @inheritdoc IOmniV3PoolDeployer
    Parameters public override parameters;

    /// @notice Address of the OmniV3Factory contract
    address public factoryAddress;

    /// @dev Prevents calling a function from anyone except the OmniV3Factory contract address
    modifier onlyFactory() {
        require(msg.sender == factoryAddress, "only factory can call deploy");
        _;
    }

    /// @notice Sets the OmniV3Factory address
    /// @param _factoryAddress Address of the OmniV3Factory contract
    function setFactoryAddress(address _factoryAddress) external {
        require(factoryAddress == address(0), "already initialized");

        factoryAddress = _factoryAddress;

        emit SetFactoryAddress(_factoryAddress);
    }

    /// @inheritdoc IOmniV3PoolDeployer
    function deploy(
        address factory,
        address token0,
        address token1,
        uint24 fee,
        int24 tickSpacing
    ) external override onlyFactory returns (address pool) {
        parameters = Parameters({factory: factory, token0: token0, token1: token1, fee: fee, tickSpacing: tickSpacing});
        pool = address(new OmniV3Pool{salt: keccak256(abi.encode(token0, token1, fee))}());
        delete parameters;
    }
}
