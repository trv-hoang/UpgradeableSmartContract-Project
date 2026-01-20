// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/vulnerable/BadProxy.sol";
import "../src/vulnerable/VulnerableLogicV1.sol";
import "../src/secure/SecureLogicV1.sol";
import "../src/secure/SecureLogicV2.sol";
import "../src/secure/SecureProxy.sol";

/**
 * @title GasComparisonTest
 * @notice Compares gas costs between vulnerable and secure proxy patterns.
 * @dev Measures deployment and operation costs to show security trade-offs.
 *
 * NOTE: The vulnerable BadProxy has storage collision with VulnerableLogicV1
 * (both use slot 0), so we focus on deployment and upgrade gas costs.
 * The storage collision itself is demonstrated in 1_StorageCollision.t.sol.
 */
contract GasComparisonTest is Test {
    address public owner = address(this);

    /**
     * @notice Compare deployment gas costs
     */
    function testDeploymentGas() public {
        console.log("=== Deployment Gas Comparison ===\n");

        // --- Vulnerable Pattern ---
        uint256 gasStart = gasleft();
        VulnerableLogicV1 vulnImpl = new VulnerableLogicV1();
        uint256 vulnImplGas = gasStart - gasleft();

        gasStart = gasleft();
        BadProxy vulnProxy = new BadProxy(address(vulnImpl));
        uint256 vulnProxyGas = gasStart - gasleft();

        // Note: We skip initialize for vulnerable as it corrupts storage
        uint256 vulnTotalGas = vulnImplGas + vulnProxyGas;

        console.log("VULNERABLE PATTERN:");
        console.log("  Implementation deploy:", vulnImplGas);
        console.log("  Proxy deploy:", vulnProxyGas);
        console.log("  TOTAL:", vulnTotalGas);

        // --- Secure Pattern ---
        gasStart = gasleft();
        SecureLogicV1 secImpl = new SecureLogicV1();
        uint256 secImplGas = gasStart - gasleft();

        bytes memory initData = abi.encodeCall(SecureLogicV1.initialize, (owner));

        gasStart = gasleft();
        SecureProxy secProxy = new SecureProxy(address(secImpl), initData);
        uint256 secProxyGas = gasStart - gasleft();

        uint256 secTotalGas = secImplGas + secProxyGas;

        console.log("\nSECURE PATTERN:");
        console.log("  Implementation deploy:", secImplGas);
        console.log("  Proxy deploy (includes init):", secProxyGas);
        console.log("  TOTAL:", secTotalGas);

        // --- Comparison ---
        console.log("\n=== COMPARISON ===");
        if (secTotalGas > vulnTotalGas) {
            console.log("Secure pattern costs", secTotalGas - vulnTotalGas, "more gas");
            console.log("Overhead percentage:", (secTotalGas - vulnTotalGas) * 100 / vulnTotalGas, "%");
        } else {
            console.log("Secure pattern saves", vulnTotalGas - secTotalGas, "gas!");
        }

        // Clean up references
        require(address(vulnProxy) != address(0));
        require(address(secProxy) != address(0));
    }

    /**
     * @notice Compare secure proxy operation gas costs
     * @dev We only test secure proxy operations as BadProxy has storage collision
     */
    function testSecureOperationGas() public {
        // Setup Secure proxy
        SecureLogicV1 secImpl = new SecureLogicV1();
        bytes memory initData = abi.encodeCall(SecureLogicV1.initialize, (owner));
        SecureProxy secProxy = new SecureProxy(address(secImpl), initData);

        console.log("=== Secure Proxy Operation Gas ===\n");

        // --- setValue ---
        uint256 gasStart = gasleft();
        SecureLogicV1(address(secProxy)).setValue(100);
        uint256 setValueGas = gasStart - gasleft();

        console.log("setValue(100):", setValueGas);

        // --- increment ---
        gasStart = gasleft();
        SecureLogicV1(address(secProxy)).increment();
        uint256 incrementGas = gasStart - gasleft();

        console.log("increment():", incrementGas);

        // --- Read value ---
        gasStart = gasleft();
        uint256 val = SecureLogicV1(address(secProxy)).value();
        uint256 readGas = gasStart - gasleft();

        console.log("value() read:", readGas);
        console.log("Current value:", val);
    }

    /**
     * @notice Compare upgrade gas costs
     */
    function testUpgradeGas() public {
        console.log("=== Upgrade Gas Comparison ===\n");

        // --- Setup Vulnerable (just for upgrade comparison) ---
        VulnerableLogicV1 vulnImpl1 = new VulnerableLogicV1();
        BadProxy vulnProxy = new BadProxy(address(vulnImpl1));
        // Skip initialize to avoid storage collision

        VulnerableLogicV1 vulnImpl2 = new VulnerableLogicV1(); // "V2"

        // --- Setup Secure ---
        SecureLogicV1 secImpl1 = new SecureLogicV1();
        bytes memory initData = abi.encodeCall(SecureLogicV1.initialize, (owner));
        SecureProxy secProxy = new SecureProxy(address(secImpl1), initData);

        SecureLogicV2 secImpl2 = new SecureLogicV2();

        // --- Upgrade Vulnerable ---
        uint256 gasStart = gasleft();
        vulnProxy.upgradeTo(address(vulnImpl2));
        uint256 vulnUpgradeGas = gasStart - gasleft();

        // --- Upgrade Secure (UUPS) ---
        gasStart = gasleft();
        SecureLogicV1(address(secProxy)).upgradeToAndCall(address(secImpl2), "");
        uint256 secUpgradeGas = gasStart - gasleft();

        console.log("Upgrade to new implementation:");
        console.log("  Vulnerable (BadProxy.upgradeTo):", vulnUpgradeGas);
        console.log("  Secure (UUPS.upgradeToAndCall):", secUpgradeGas);
        console.log("  Difference:", _absDiff(vulnUpgradeGas, secUpgradeGas));

        // --- Upgrade with reinitialization ---
        SecureLogicV1 secImpl1b = new SecureLogicV1();
        SecureProxy secProxy2 = new SecureProxy(address(secImpl1b), abi.encodeCall(SecureLogicV1.initialize, (owner)));

        SecureLogicV2 secImpl2b = new SecureLogicV2();

        bytes memory reinitData = abi.encodeCall(SecureLogicV2.initializeV2, ());

        gasStart = gasleft();
        SecureLogicV1(address(secProxy2)).upgradeToAndCall(address(secImpl2b), reinitData);
        uint256 secUpgradeWithInitGas = gasStart - gasleft();

        console.log("\nUpgrade with reinitialization:");
        console.log("  Secure (upgradeToAndCall + initializeV2):", secUpgradeWithInitGas);
    }

    /**
     * @notice Summary of all gas comparisons
     */
    function testGasSummary() public {
        console.log("========================================");
        console.log("       GAS COST SUMMARY");
        console.log("========================================\n");

        // Deployment
        VulnerableLogicV1 vulnImpl = new VulnerableLogicV1();
        BadProxy vulnProxy = new BadProxy(address(vulnImpl));

        SecureLogicV1 secImpl = new SecureLogicV1();

        console.log("Implementation Contract Size:");
        console.log("  VulnerableLogicV1:", address(vulnImpl).code.length, "bytes");
        console.log("  SecureLogicV1:", address(secImpl).code.length, "bytes");

        console.log("\nProxy Contract Size:");
        console.log("  BadProxy:", address(vulnProxy).code.length, "bytes");

        bytes memory initData = abi.encodeCall(SecureLogicV1.initialize, (owner));
        SecureProxy secProxy = new SecureProxy(address(secImpl), initData);
        console.log("  SecureProxy (ERC1967):", address(secProxy).code.length, "bytes");

        console.log("\n========================================");
        console.log("CONCLUSION: Secure patterns have higher");
        console.log("deployment cost but provide critical");
        console.log("security against storage collision and");
        console.log("uninitialized implementation attacks!");
        console.log("========================================");
    }

    // Helper function to get absolute difference
    function _absDiff(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : b - a;
    }
}
