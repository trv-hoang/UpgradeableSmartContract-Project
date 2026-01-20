// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./VulnerableLogicV1.sol";

/**
 * @title VulnerableLogicV2
 * @notice VULNERABLE: This contract causes Storage Collision when upgrading from V1.
 * @dev Demonstrates the "Storage Collision" vulnerability.
 * 
 * VULNERABILITY:
 * - collisionVar is declared BEFORE the inherited variables
 * - In Solidity, child contract variables are laid out AFTER parent variables
 * - But we're intentionally breaking this by declaring collisionVar first
 * - This causes collisionVar to occupy the same slot as a critical variable
 * 
 * Storage Layout Problem:
 * - VulnerableLogicV1: slot 0 = value, slot 1 = owner
 * - VulnerableLogicV2 (WRONG): slot 0 = collisionVar, slot 1 = value, slot 2 = owner
 * - When proxy delegates to V2, writing to collisionVar overwrites slot 0
 */
contract VulnerableLogicV2 {
    // VULNERABILITY: This variable is at slot 0, same as V1's 'value'
    // In the BadProxy context, slot 0 stores the implementation address!
    uint256 public collisionVar;
    
    // These should match V1's layout, but they're shifted by 1 slot
    uint256 public value;
    address public owner;
    
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
    
    /**
     * @notice Sets collisionVar - THIS WILL CORRUPT STORAGE
     * @dev When called through BadProxy, this overwrites the implementation address
     */
    function setCollisionVar(uint256 _val) public {
        collisionVar = _val;
    }
    
    function upgradeTo(address newImplementation) public {
        require(msg.sender == owner, "Not owner");
        assembly {
            sstore(0, newImplementation)
        }
    }
}
