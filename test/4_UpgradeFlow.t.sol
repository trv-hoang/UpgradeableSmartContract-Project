// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/secure/SecureLogicV1.sol";
import "../src/secure/SecureLogicV2.sol";
import "../src/secure/SecureProxy.sol";

/**
 * @title UpgradeFlowTest
 * @notice Verify upgrade workflow as described in Chapter 5
 * @dev Proof: Logic changes but State is preserved
 */
contract UpgradeFlowTest is Test {
    SecureLogicV1 public implV1;
    SecureLogicV2 public implV2;
    SecureProxy public proxy;

    address public admin = address(this);
    address public user = makeAddr("user");

    function setUp() public {
        implV1 = new SecureLogicV1();
        bytes memory initData = abi.encodeCall(SecureLogicV1.initialize, (admin));
        proxy = new SecureProxy(address(implV1), initData);
        implV2 = new SecureLogicV2();
    }

    function testFullUpgradeFlow() public {
        console.log("=== CHAPTER 5 WORKFLOW VERIFICATION ===\n");

        SecureLogicV1 proxyV1 = SecureLogicV1(address(proxy));

        // STEP 1: Verify V1
        assertEq(proxyV1.version(), "1.0.0");
        assertEq(proxyV1.owner(), admin);

        // STEP 2: Interact with V1
        proxyV1.setValue(42);
        proxyV1.increment();
        uint256 valueBefore = proxyV1.value();
        assertEq(valueBefore, 43);

        // STEP 3: Upgrade to V2
        bytes memory reinitData = abi.encodeCall(SecureLogicV2.initializeV2, ());
        proxyV1.upgradeToAndCall(address(implV2), reinitData);

        // STEP 4: Verify state preservation
        SecureLogicV2 proxyV2 = SecureLogicV2(address(proxy));
        assertEq(proxyV2.version(), "2.0.0");
        assertEq(proxyV2.value(), valueBefore, "Value preserved");
        assertEq(proxyV2.newVar(), 100);
        assertEq(proxyV2.getTotal(), 143);

        console.log("[PASS] State preserved: value = 43");
        console.log("[PASS] Logic changed: V1 -> V2");
    }

    function testOwnerPreservedAfterUpgrade() public {
        SecureLogicV1 proxyV1 = SecureLogicV1(address(proxy));
        address ownerBefore = proxyV1.owner();

        bytes memory reinitData = abi.encodeCall(SecureLogicV2.initializeV2, ());
        proxyV1.upgradeToAndCall(address(implV2), reinitData);

        SecureLogicV2 proxyV2 = SecureLogicV2(address(proxy));
        assertEq(proxyV2.owner(), ownerBefore);
    }

    function testOnlyOwnerCanUpgrade() public {
        SecureLogicV1 proxyV1 = SecureLogicV1(address(proxy));

        vm.prank(user);
        vm.expectRevert();
        proxyV1.upgradeToAndCall(address(implV2), "");
    }

    function testV2FunctionsWork() public {
        SecureLogicV1 proxyV1 = SecureLogicV1(address(proxy));
        proxyV1.setValue(50);

        bytes memory reinitData = abi.encodeCall(SecureLogicV2.initializeV2, ());
        proxyV1.upgradeToAndCall(address(implV2), reinitData);

        SecureLogicV2 proxyV2 = SecureLogicV2(address(proxy));
        assertEq(proxyV2.value(), 50);
        assertEq(proxyV2.getTotal(), 150);

        proxyV2.setNewVar(200);
        assertEq(proxyV2.getTotal(), 250);
    }

    function testReinitializerOnlyOnce() public {
        SecureLogicV1 proxyV1 = SecureLogicV1(address(proxy));

        bytes memory reinitData = abi.encodeCall(SecureLogicV2.initializeV2, ());
        proxyV1.upgradeToAndCall(address(implV2), reinitData);

        SecureLogicV2 proxyV2 = SecureLogicV2(address(proxy));
        vm.expectRevert();
        proxyV2.initializeV2();
    }
}
