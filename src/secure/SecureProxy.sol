// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title SecureProxy
 * @notice SECURE: ERC1967-compliant proxy using OpenZeppelin's implementation.
 * @dev Demonstrates correct proxy pattern:
 * 
 * SECURITY FEATURES:
 * 1. Uses EIP-1967 storage slots - implementation at predictable, collision-free slot
 * 2. Implementation slot: keccak256("eip1967.proxy.implementation") - 1
 * 3. Admin slot: keccak256("eip1967.proxy.admin") - 1
 * 4. Built on battle-tested OpenZeppelin code
 * 
 * EIP-1967 SLOTS:
 * - Implementation: 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
 * - Admin: 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
 * - Beacon: 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50
 */
contract SecureProxy is ERC1967Proxy {
    /**
     * @notice Deploy the proxy pointing to an implementation
     * @param _logic Address of the implementation contract
     * @param _data Initialization calldata (typically encodeWithSelector for initialize)
     */
    constructor(address _logic, bytes memory _data) ERC1967Proxy(_logic, _data) {}
}
