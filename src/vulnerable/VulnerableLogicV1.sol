// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title VulnerableLogicV1
 * @notice VULNERABLE: This contract lacks proper initialization protection.
 * @dev Demonstrates the "Uninitialized Implementation" vulnerability.
 *
 * VULNERABILITY:
 * - No constructor calling _disableInitializers()
 * - Anyone can call initialize() on the implementation contract directly
 * - If attacker becomes owner, they can call destroy() to selfdestruct
 */
contract VulnerableLogicV1 {
    // Storage slot 0
    uint256 public value;
    // Storage slot 1
    address public owner;

    // VULNERABLE: No protection - anyone can initialize the implementation
    function initialize() public {
        owner = msg.sender;
    }

    function setValue(uint256 _value) public {
        require(msg.sender == owner, "Not owner");
        value = _value;
    }

    function increment() public {
        require(msg.sender == owner, "Not owner");
        value += 1;
    }

    // Upgrade function - sets new implementation
    function upgradeTo(address newImplementation) public {
        require(msg.sender == owner, "Not owner");
        // In a real proxy, this would update the implementation slot
        // For demo purposes, we'll use assembly to write to slot used by BadProxy
        assembly {
            sstore(0, newImplementation)
        }
    }

    /**
     * @notice DANGEROUS: Allows owner to destroy the contract
     * @dev Used to demonstrate the impact of uninitialized implementation attack
     */
    function destroy() public {
        require(msg.sender == owner, "Not owner");
        selfdestruct(payable(msg.sender));
    }
}
