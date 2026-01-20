// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/vulnerable/BadProxy.sol";
import "../src/vulnerable/VulnerableLogicV1.sol";
import "../src/vulnerable/VulnerableLogicV2.sol";

/**
 * @title StorageCollisionTest
 * @notice Demonstrates Storage Collision vulnerability in upgradeable proxies.
 * @dev This test proves that poor storage layout can corrupt critical proxy data.
 * 
 * ATTACK SCENARIO:
 * 1. Deploy BadProxy pointing to VulnerableLogicV1
 * 2. Initialize through proxy (owner is set)
 * 3. Upgrade to VulnerableLogicV2 (which has collisionVar at slot 0)
 * 4. Call setCollisionVar() through proxy
 * 5. This overwrites slot 0 - which is the implementation address in BadProxy!
 * 6. Proxy is now broken - delegatecall goes to wrong address
 */
contract StorageCollisionTest is Test {
    BadProxy public proxy;
    VulnerableLogicV1 public logicV1;
    VulnerableLogicV2 public logicV2;
    
    address public owner = address(this);
    address public attacker = address(0xBAD);
    
    function setUp() public {
        // Deploy V1 logic
        logicV1 = new VulnerableLogicV1();
        
        // Deploy V2 logic (with storage collision bug)
        logicV2 = new VulnerableLogicV2();
        
        // Deploy BadProxy pointing to V1
        proxy = new BadProxy(address(logicV1));
        
        // Initialize through proxy
        VulnerableLogicV1(address(proxy)).initialize();
        
        console.log("=== Initial Setup ===");
        console.log("LogicV1 address:", address(logicV1));
        console.log("LogicV2 address:", address(logicV2));
        console.log("Proxy implementation (slot 0):", proxy.implementation());
    }
    
    /**
     * @notice Demonstrates storage collision when upgrading
     * @dev The collisionVar in V2 occupies the same slot as proxy's implementation
     */
    function testCollision() public {
        console.log("\n=== Before Upgrade ===");
        console.log("Proxy implementation:", proxy.implementation());
        assertEq(proxy.implementation(), address(logicV1), "Should point to V1");
        
        // Upgrade to V2 through proxy's upgradeTo
        proxy.upgradeTo(address(logicV2));
        
        console.log("\n=== After Upgrade to V2 ===");
        console.log("Proxy implementation:", proxy.implementation());
        assertEq(proxy.implementation(), address(logicV2), "Should point to V2");
        
        // Now call setCollisionVar through the proxy
        // This writes to slot 0 in the proxy's storage context!
        console.log("\n=== Calling setCollisionVar(9999) ===");
        VulnerableLogicV2(address(proxy)).setCollisionVar(9999);
        
        // Read slot 0 directly - it should now be 9999, NOT the V2 address!
        bytes32 slot0Value;
        assembly {
            slot0Value := sload(0)
        }
        
        address corruptedImplementation = proxy.implementation();
        
        console.log("\n=== After Storage Collision ===");
        console.log("Slot 0 value:", uint256(slot0Value));
        console.log("Corrupted implementation:", corruptedImplementation);
        
        // PROVE THE VULNERABILITY: implementation is now 9999, not V2!
        assertEq(
            corruptedImplementation, 
            address(uint160(9999)), 
            "Implementation corrupted to 9999!"
        );
        
        // The proxy is now completely broken
        assertFalse(
            corruptedImplementation == address(logicV2),
            "Implementation should NOT be V2 anymore"
        );
        
        console.log("\n[VULNERABILITY PROVEN] Storage collision corrupted proxy!");
    }
    
    /**
     * @notice Shows what happens when trying to use the corrupted proxy
     * @dev After corruption, the proxy delegates to an invalid address
     */
    function testCollisionBreaksProxy() public {
        // Upgrade to V2
        proxy.upgradeTo(address(logicV2));
        
        // Corrupt the implementation
        VulnerableLogicV2(address(proxy)).setCollisionVar(9999);
        
        // Now the implementation is address(9999) which has no code
        // Calling through proxy will succeed but do nothing (delegatecall to EOA)
        // Or fail depending on the function
        
        // Verify the implementation is corrupted
        assertEq(proxy.implementation(), address(uint160(9999)));
        
        // The proxy is bricked - it points to address 9999 which has no code
        console.log("Proxy implementation after corruption:", proxy.implementation());
        console.log("[PROVEN] Proxy is now pointing to invalid address 9999!");
    }
    
    /**
     * @notice Demonstrates that reading slot 0 shows the collision
     */
    function testSlot0Collision() public {
        // Before: slot 0 = implementation address
        bytes32 slot0Before = vm.load(address(proxy), bytes32(uint256(0)));
        assertEq(address(uint160(uint256(slot0Before))), address(logicV1));
        
        // Upgrade
        proxy.upgradeTo(address(logicV2));
        
        // After upgrade: slot 0 = V2 address
        bytes32 slot0AfterUpgrade = vm.load(address(proxy), bytes32(uint256(0)));
        assertEq(address(uint160(uint256(slot0AfterUpgrade))), address(logicV2));
        
        // Corrupt via setCollisionVar
        VulnerableLogicV2(address(proxy)).setCollisionVar(0xDEADBEEF);
        
        // After collision: slot 0 = 0xDEADBEEF
        bytes32 slot0AfterCollision = vm.load(address(proxy), bytes32(uint256(0)));
        assertEq(uint256(slot0AfterCollision), 0xDEADBEEF);
        
        console.log("Slot 0 before:", uint256(slot0Before));
        console.log("Slot 0 after upgrade:", uint256(slot0AfterUpgrade));
        console.log("Slot 0 after collision:", uint256(slot0AfterCollision));
    }
}
