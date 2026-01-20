// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/vulnerable/VulnerableLogicV1.sol";
import "../src/secure/SecureLogicV1.sol";
import "../src/secure/SecureProxy.sol";

/**
 * @title UninitializedImplementationTest
 * @notice Demonstrates the "Uninitialized Implementation" vulnerability.
 * @dev Tests show how attackers can take over unprotected implementation contracts.
 *
 * ATTACK SCENARIO:
 * 1. Protocol deploys VulnerableLogicV1 as implementation (without proper protection)
 * 2. Protocol deploys proxy pointing to VulnerableLogicV1
 * 3. Attacker finds the implementation address (it's on-chain, easy to find)
 * 4. Attacker calls initialize() DIRECTLY on the implementation contract
 * 5. Attacker becomes owner of the implementation
 * 6. Attacker can now manipulate the implementation contract state
 *
 * NOTE: Post-Cancun (EIP-6780), selfdestruct only works in the same transaction
 * as contract creation. We demonstrate the vulnerability by showing ownership takeover.
 */
contract UninitializedImplementationTest is Test {
    VulnerableLogicV1 public vulnerableLogic;
    SecureLogicV1 public secureLogic;

    address public deployer = address(this);
    address public attacker = makeAddr("attacker");

    function setUp() public {
        // Deploy vulnerable implementation (no protection)
        vulnerableLogic = new VulnerableLogicV1();

        // Deploy secure implementation (with _disableInitializers)
        secureLogic = new SecureLogicV1();
    }

    /**
     * @notice Attacker takes over vulnerable implementation
     * @dev Demonstrates complete takeover of unprotected implementation
     *
     * NOTE: Post-Cancun (EIP-6780), selfdestruct no longer deletes code
     * when called in a different transaction than contract creation.
     * We demonstrate the attack by showing the attacker becomes owner.
     */
    function testTakeoverVulnerable() public {
        console.log("=== Uninitialized Implementation Attack ===\n");

        // Step 1: Verify implementation exists and has code
        console.log("Step 1: Implementation deployed");
        console.log("Implementation address:", address(vulnerableLogic));
        console.log("Initial owner:", vulnerableLogic.owner());
        assertEq(vulnerableLogic.owner(), address(0), "Owner should be zero initially");

        // Step 2: Attacker calls initialize() directly on implementation
        console.log("\nStep 2: Attacker initializes the implementation directly");
        vm.prank(attacker);
        vulnerableLogic.initialize();

        // Step 3: Verify attacker is now owner
        console.log("Step 3: Attacker is now owner");
        console.log("Owner of implementation:", vulnerableLogic.owner());
        assertEq(vulnerableLogic.owner(), attacker, "Attacker should be owner");

        // Step 4: Attacker can now manipulate the implementation
        console.log("\nStep 4: Attacker can now control the implementation");
        vm.prank(attacker);
        vulnerableLogic.setValue(12345);
        assertEq(vulnerableLogic.value(), 12345, "Attacker can set value");

        console.log("\n[VULNERABILITY PROVEN] Attacker took over the implementation!");
        console.log("Impact: Attacker now controls the implementation contract.");
        console.log("In pre-Cancun EVM, attacker could also selfdestruct the contract.");
    }

    /**
     * @notice Demonstrates that secure implementation cannot be taken over
     * @dev _disableInitializers() in constructor prevents initialization
     */
    function testSecureCannotTakeover() public {
        console.log("=== Secure Implementation Protection ===\n");

        console.log("Attempting to initialize SecureLogicV1 implementation directly...");
        console.log("Implementation address:", address(secureLogic));

        // Attacker tries to call initialize() on the secure implementation
        // This should revert because _disableInitializers() was called in constructor
        vm.prank(attacker);
        vm.expectRevert(); // Will revert with "Initializable: contract is already initialized"
        secureLogic.initialize(attacker);

        console.log("[PROTECTION VERIFIED] initialize() reverted as expected!");
        console.log("SecureLogicV1 is protected by _disableInitializers()");
    }

    /**
     * @notice Shows proper usage of secure implementation via proxy
     */
    function testSecureProxyInitialization() public {
        console.log("=== Proper Secure Proxy Usage ===\n");

        // Deploy new secure implementation for this test
        SecureLogicV1 impl = new SecureLogicV1();

        // Create initialization data
        bytes memory initData = abi.encodeCall(SecureLogicV1.initialize, (deployer));

        // Deploy proxy with initialization
        SecureProxy proxy = new SecureProxy(address(impl), initData);

        // Wrap proxy with logic interface
        SecureLogicV1 proxied = SecureLogicV1(address(proxy));

        // Verify initialization worked through proxy
        console.log("Proxy owner:", proxied.owner());
        console.log("Proxy value:", proxied.value());
        console.log("Proxy version:", proxied.version());

        assertEq(proxied.owner(), deployer, "Owner should be deployer");
        assertEq(proxied.version(), "1.0.0", "Version should be 1.0.0");

        // Verify the implementation itself cannot be initialized
        vm.expectRevert();
        impl.initialize(attacker);

        console.log("\n[SUCCESS] Proxy works correctly, implementation protected!");
    }

    /**
     * @notice Shows the theoretical impact if attacker controls implementation
     * @dev In pre-Cancun EVM, this would brick all proxies
     */
    function testAttackerControlsImplementation() public {
        console.log("=== Attacker Control Demonstration ===\n");

        // Attacker takes over implementation
        vm.prank(attacker);
        vulnerableLogic.initialize();

        // Attacker can now call any owner-only functions on the IMPLEMENTATION
        // (Not through proxy, but directly on the implementation contract)

        console.log("Before attacker modification:");
        console.log("  Implementation value:", vulnerableLogic.value());

        vm.prank(attacker);
        vulnerableLogic.setValue(999);

        console.log("\nAfter attacker modification:");
        console.log("  Implementation value:", vulnerableLogic.value());

        assertEq(vulnerableLogic.value(), 999);

        console.log("\n[IMPACT] Attacker fully controls the implementation contract!");
        console.log("While proxy state is separate, this is a severe security issue.");
        console.log("In pre-Cancun EVM, attacker could selfdestruct and brick all proxies.");
    }
}
