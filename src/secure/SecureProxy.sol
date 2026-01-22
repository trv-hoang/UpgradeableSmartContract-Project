// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

/**
 * @title SecureProxy
 * @notice SECURE: ERC1967-compliant proxy using OpenZeppelin's battle-tested implementation.
 * @dev This proxy demonstrates the correct way to implement upgradeable contracts.
 *
 * SECURITY FEATURES:
 * 1. Uses EIP-1967 storage slots - implementation stored at predictable, collision-free location
 * 2. Implementation slot: keccak256("eip1967.proxy.implementation") - 1
 * 3. Built on OpenZeppelin's audited code
 *
 * EIP-1967 STORAGE SLOTS:
 * - Implementation: 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
 * - Admin: 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
 * - Beacon: 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50
 *
 * INHERITANCE CHAIN:
 * SecureProxy -> ERC1967Proxy -> Proxy (contains fallback)
 */
contract SecureProxy is ERC1967Proxy {
    /**
     * @notice Deploy the proxy and initialize the implementation
     * @param _logic Address of the implementation contract (e.g., SecureLogicV1)
     * @param _data Initialization calldata (e.g., abi.encodeCall(SecureLogicV1.initialize, (owner)))
     * @dev The _data is executed via delegatecall during deployment for atomic initialization
     */
    constructor(address _logic, bytes memory _data) ERC1967Proxy(_logic, _data) {}

    /**
     * @notice Get the current implementation address
     * @return The address of the current implementation contract
     * @dev Reads from EIP-1967 implementation slot (0x360894...)
     */
    function getImplementation() external view returns (address) {
        return ERC1967Utils.getImplementation();
    }

    /**
     * @notice Get the EIP-1967 implementation storage slot
     * @return The bytes32 slot where implementation address is stored
     * @dev This slot is: keccak256("eip1967.proxy.implementation") - 1
     */
    function getImplementationSlot() external pure returns (bytes32) {
        // 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
        return bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    }

    /**
     * @notice Verify this is an EIP-1967 compliant proxy
     * @return Always returns true for this contract
     */
    function isEIP1967Proxy() external pure returns (bool) {
        return true;
    }
}
