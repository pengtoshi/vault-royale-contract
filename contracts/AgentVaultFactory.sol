// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./AgentVault.sol";
import "./interface/IAgentVaultFactory.sol";

/**
 * @title AgentVaultFactory
 * @notice Factory contract for deploying and managing AgentVault contracts
 */
contract AgentVaultFactory is IAgentVaultFactory, Initializable, OwnableUpgradeable, UUPSUpgradeable {
    /// @notice Array to store all deployed vault addresses
    address[] public vaults;
    /// @notice Initial fund for agent
    uint256 public agentInitialFund;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 _agentInitialFund) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        agentInitialFund = _agentInitialFund;
    }

    /// @inheritdoc IAgentVaultFactory
    function createVault(
        IERC20 asset,
        IStrategy strategy,
        address vaultMaster,
        address agent,
        string memory name,
        string memory symbol
    ) external payable returns (address vault) {
        require(address(asset) != address(0), "ERC20: invalid contract address");
        require(vaultMaster != address(0), "Vault: invalid vault master");
        require(msg.value >= agentInitialFund, "Vault: insufficient initial fund");

        vault = address(new AgentVault(asset, strategy, vaultMaster, agent, name, symbol));
        vaults.push(vault);

        (bool success, ) = payable(agent).call{value: agentInitialFund}("");
        require(success, "Vault: failed to transfer initial fund to agent");

        emit VaultCreated(vault, address(asset), name, symbol);
    }

    /// @inheritdoc IAgentVaultFactory
    function getAllVaults() external view returns (address[] memory) {
        return vaults;
    }

    /// @inheritdoc IAgentVaultFactory
    function getVaultCount() external view returns (uint256) {
        return vaults.length;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
