// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "./interfaces/IOmniV3Factory.sol";
import "./interfaces/IOmniV3PoolDeployer.sol";
import "./interfaces/IOmniV3Pool.sol";

/// @title Canonical Omni Exchange V3 Factory
/// @notice Deploys Omni Exchange V3 liquidity pools and manages ownership and control over pool protocol fees
contract OmniV3Factory is IOmniV3Factory {
    /// @inheritdoc IOmniV3Factory
    address public override owner;

    /// @notice Address of the OmniV3PoolDeployer contract
    address public immutable poolDeployer;

    /// @notice Address of the OmniV3LmPoolDeployer contract
    address public lmPoolDeployer;

    /// @inheritdoc IOmniV3Factory
    mapping(uint24 => int24) public override feeAmountTickSpacing;

    /// @inheritdoc IOmniV3Factory
    mapping(address => mapping(address => mapping(uint24 => address))) public override getPool;

    /// @inheritdoc IOmniV3Factory
    mapping(uint24 => TickSpacingExtraInfo) public override feeAmountTickSpacingExtraInfo;

    /// @dev Contains information on whitelisted addresses
    mapping(address => bool) private _whiteListAddresses;

    /// @dev Prevents calling a function from anyone except the contract owner's address
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /// @dev Prevents calling a function from anyone except the owner's or OmniV3LmPoolDeployer contract addresses
    modifier onlyOwnerOrLmPoolDeployer() {
        require(msg.sender == owner || msg.sender == lmPoolDeployer, "Not owner or LM pool deployer");
        _;
    }

    /// @dev Constructor
    /// @param _poolDeployer Address of the OmniV3PoolDeployer contract
    constructor(address _poolDeployer) {
        poolDeployer = _poolDeployer;
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);

        feeAmountTickSpacing[100] = 1;
        feeAmountTickSpacingExtraInfo[100] = TickSpacingExtraInfo({whitelistRequested: false, enabled: true});
        emit FeeAmountEnabled(100, 1);
        emit FeeAmountExtraInfoUpdated(100, false, true);
        feeAmountTickSpacing[500] = 10;
        feeAmountTickSpacingExtraInfo[500] = TickSpacingExtraInfo({whitelistRequested: false, enabled: true});
        emit FeeAmountEnabled(500, 10);
        emit FeeAmountExtraInfoUpdated(500, false, true);
        feeAmountTickSpacing[2500] = 50;
        feeAmountTickSpacingExtraInfo[2500] = TickSpacingExtraInfo({whitelistRequested: false, enabled: true});
        emit FeeAmountEnabled(2500, 50);
        emit FeeAmountExtraInfoUpdated(2500, false, true);
        feeAmountTickSpacing[10000] = 200;
        feeAmountTickSpacingExtraInfo[10000] = TickSpacingExtraInfo({whitelistRequested: false, enabled: true});
        emit FeeAmountEnabled(10000, 200);
        emit FeeAmountExtraInfoUpdated(10000, false, true);
    }

    /// @inheritdoc IOmniV3Factory
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external override returns (address pool) {
        require(tokenA != tokenB);
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0));
        int24 tickSpacing = feeAmountTickSpacing[fee];
        TickSpacingExtraInfo memory info = feeAmountTickSpacingExtraInfo[fee];
        require(tickSpacing != 0 && info.enabled, "fee is not available yet");
        if (info.whitelistRequested) {
            require(_whiteListAddresses[msg.sender], "user should be in the white list for this fee tier");
        }
        require(getPool[token0][token1][fee] == address(0));
        pool = IOmniV3PoolDeployer(poolDeployer).deploy(address(this), token0, token1, fee, tickSpacing);
        getPool[token0][token1][fee] = pool;
        // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
        getPool[token1][token0][fee] = pool;
        emit PoolCreated(token0, token1, fee, tickSpacing, pool);
    }

    /// @inheritdoc IOmniV3Factory
    function setOwner(address _owner) external override onlyOwner {
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    /// @inheritdoc IOmniV3Factory
    function enableFeeAmount(uint24 fee, int24 tickSpacing) public override onlyOwner {
        require(fee < 1000000);
        // tick spacing is capped at 16384 to prevent the situation where tickSpacing is so large that
        // TickBitmap#nextInitializedTickWithinOneWord overflows int24 container from a valid tick
        // 16384 ticks represents a >5x price change with ticks of 1 bips
        require(tickSpacing > 0 && tickSpacing < 16384);
        require(feeAmountTickSpacing[fee] == 0);

        feeAmountTickSpacing[fee] = tickSpacing;
        feeAmountTickSpacingExtraInfo[fee] = TickSpacingExtraInfo({whitelistRequested: false, enabled: true});
        emit FeeAmountEnabled(fee, tickSpacing);
        emit FeeAmountExtraInfoUpdated(fee, false, true);
    }

    /// @inheritdoc IOmniV3Factory
    function setWhiteListAddress(address user, bool verified) public override onlyOwner {
        require(_whiteListAddresses[user] != verified, "state not change");
        _whiteListAddresses[user] = verified;

        emit WhiteListAdded(user, verified);
    }

    /// @inheritdoc IOmniV3Factory
    function setFeeAmountExtraInfo(
        uint24 fee,
        bool whitelistRequested,
        bool enabled
    ) public override onlyOwner {
        require(feeAmountTickSpacing[fee] != 0);

        feeAmountTickSpacingExtraInfo[fee] = TickSpacingExtraInfo({
            whitelistRequested: whitelistRequested,
            enabled: enabled
        });
        emit FeeAmountExtraInfoUpdated(fee, whitelistRequested, enabled);
    }

    /// @inheritdoc IOmniV3Factory
    function setLmPoolDeployer(address _lmPoolDeployer) external override onlyOwner {
        lmPoolDeployer = _lmPoolDeployer;
        emit SetLmPoolDeployer(_lmPoolDeployer);
    }

    /// @inheritdoc IOmniV3Factory
    function setFeeProtocol(address pool, uint32 feeProtocol0, uint32 feeProtocol1) external override onlyOwner {
        IOmniV3Pool(pool).setFeeProtocol(feeProtocol0, feeProtocol1);
    }

    /// @inheritdoc IOmniV3Factory
    function setLmPool(address pool, address lmPool) external override onlyOwnerOrLmPoolDeployer {
        IOmniV3Pool(pool).setLmPool(lmPool);
    }

    /// @inheritdoc IOmniV3Factory
    function collectProtocol(
        address pool,
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external override onlyOwner returns (uint128 amount0, uint128 amount1) {
        return IOmniV3Pool(pool).collectProtocol(recipient, amount0Requested, amount1Requested);
    }
}
