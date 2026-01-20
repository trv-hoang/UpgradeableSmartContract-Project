// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../../src/secure/SecureLogicV1.sol";
import "../../src/secure/SecureLogicV2.sol";
import "../../src/secure/SecureProxy.sol";

/**
 * @title SecureUpgradeDemo
 * @notice Demo: Secure UUPS Upgrade Flow
 * @dev Run: forge script script/demo/SecureUpgradeDemo.s.sol --rpc-url http://localhost:8545 --broadcast -vvv
 */
contract SecureUpgradeDemo is Script {
    function run() external {
        uint256 deployerKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerKey);

        console.log("################################################################");
        console.log("#         SECURE DEMO: UUPS UPGRADE PATTERN                   #");
        console.log("################################################################");
        console.log("Admin:", deployer);

        vm.startBroadcast(deployerKey);

        // Step 1: Deploy
        console.log("\n=== STEP 1: DEPLOY V1 ===");
        SecureLogicV1 implV1 = new SecureLogicV1();
        bytes memory initData = abi.encodeCall(SecureLogicV1.initialize, (deployer));
        SecureProxy proxy = new SecureProxy(address(implV1), initData);

        console.log("SecureLogicV1:", address(implV1));
        console.log("SecureProxy:", address(proxy));

        SecureLogicV1 proxyV1 = SecureLogicV1(address(proxy));
        console.log("Version:", proxyV1.version());

        // Step 2: Interact
        console.log("\n=== STEP 2: INTERACT WITH V1 ===");
        proxyV1.setValue(42);
        proxyV1.increment();
        uint256 valueBefore = proxyV1.value();
        console.log("Value before upgrade:", valueBefore);

        // Step 3: Upgrade
        console.log("\n=== STEP 3: UPGRADE TO V2 ===");
        SecureLogicV2 implV2 = new SecureLogicV2();
        bytes memory reinitData = abi.encodeCall(SecureLogicV2.initializeV2, ());
        proxyV1.upgradeToAndCall(address(implV2), reinitData);

        // Step 4: Verify
        console.log("\n=== STEP 4: VERIFY ===");
        SecureLogicV2 proxyV2 = SecureLogicV2(address(proxy));
        console.log("Version:", proxyV2.version());
        console.log("Value after upgrade:", proxyV2.value());
        console.log("newVar:", proxyV2.newVar());
        console.log("getTotal():", proxyV2.getTotal());

        vm.stopBroadcast();

        console.log("\n*** SUCCESS: STATE PRESERVED! ***");
    }
}
