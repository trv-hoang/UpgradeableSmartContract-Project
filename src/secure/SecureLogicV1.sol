// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title SecureLogicV1
 * @notice SECURE: Properly protected upgradeable contract using UUPS pattern.
 * @dev Demonstrates correct implementation of upgradeable contracts.
 *
 * SECURITY FEATURES:
 * 1. constructor() calls _disableInitializers() - prevents initialization attacks
 * 2. Uses Initializable pattern with 'initializer' modifier
 * 3. Inherits UUPSUpgradeable for secure upgrade mechanism
 * 4. Uses OwnableUpgradeable for access control
 * 5. Includes __gap for storage upgrade safety
 */
contract SecureLogicV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    /// @notice Counter value
    uint256 public value;

    /**
     * @notice CRITICAL: Disable initializers in the implementation contract
     * @dev This prevents attackers from calling initialize() on the implementation
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the contract (called once via proxy)
     * @param initialOwner The address that will own the contract
     * @dev Can only be called once due to 'initializer' modifier
     */
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        // Note: UUPSUpgradeable in OZ v5 is stateless, no init needed
        value = 0;
    }

    /**
     * @notice Set the counter value
     * @param _value New value to set
     */
    function setValue(uint256 _value) public onlyOwner {
        value = _value;
    }

    /**
     * @notice Increment the counter
     */
    function increment() public onlyOwner {
        value += 1;
    }

    /**
     * @notice Returns the contract version
     * @return Version string
     */
    function version() public pure virtual returns (string memory) {
        return "1.0.0";
    }

    /**
     * @notice Authorization check for upgrades
     * @dev Only owner can upgrade - required by UUPSUpgradeable
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @notice Storage gap to allow future storage additions
     * @dev Reserves 50 slots for future use in upgrades
     * When adding new variables in V2, reduce __gap size accordingly
     */
    uint256[50] private __gap;
}
