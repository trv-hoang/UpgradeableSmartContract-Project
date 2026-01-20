// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./SecureLogicV1.sol";

/**
 * @title SecureLogicV2
 * @notice SECURE: Properly upgraded contract maintaining storage layout.
 * @dev Demonstrates correct upgrade pattern:
 *
 * UPGRADE SAFETY:
 * 1. Inherits from V1 - preserves storage layout
 * 2. New variables declared AFTER inherited storage, BEFORE __gap
 * 3. Reduced __gap size to account for new variable
 * 4. Uses reinitializer(2) for upgrade-specific initialization
 */
contract SecureLogicV2 is SecureLogicV1 {
    /// @notice New variable added in V2 - placed after V1 variables
    uint256 public newVar;

    /**
     * @notice CRITICAL: Disable initializers in implementation
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Reinitialize for V2 upgrade
     * @dev Uses reinitializer(2) - can only be called once per version
     */
    function initializeV2() public reinitializer(2) {
        newVar = 100; // Initialize new variable
    }

    /**
     * @notice Set the new variable
     * @param _val New value to set
     */
    function setNewVar(uint256 _val) public onlyOwner {
        newVar = _val;
    }

    /**
     * @notice Returns the contract version
     * @return Version string
     */
    function version() public pure override returns (string memory) {
        return "2.0.0";
    }

    /**
     * @notice Demonstrates new functionality in V2
     * @return Sum of value and newVar
     */
    function getTotal() public view returns (uint256) {
        return value + newVar;
    }

    /**
     * @notice Reduced storage gap (49 instead of 50)
     * @dev We added 1 new variable (newVar), so gap is reduced by 1
     */
    uint256[49] private __gap;
}
