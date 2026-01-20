// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title BadProxy
 * @notice VULNERABLE: Stores implementation address at slot 0 instead of EIP-1967 slot.
 * @dev Demonstrates improper proxy storage pattern.
 * 
 * VULNERABILITY:
 * - Implementation address stored at slot 0
 * - Logic contracts typically use slot 0 for their first variable
 * - When logic contract writes to its first variable, it overwrites implementation address
 * - This breaks the proxy completely
 * 
 * CORRECT PATTERN (EIP-1967):
 * - Implementation should be at: keccak256("eip1967.proxy.implementation") - 1
 * - This slot is practically unreachable by normal storage variables
 */
contract BadProxy {
    // VULNERABILITY: Implementation at slot 0 - easily overwritten!
    address public implementation;
    
    constructor(address _implementation) {
        implementation = _implementation;
    }
    
    /**
     * @notice Upgrade to a new implementation
     * @dev Stores at slot 0 - vulnerable to collision
     */
    function upgradeTo(address _newImplementation) external {
        implementation = _newImplementation;
    }
    
    /**
     * @notice Delegates all calls to the implementation contract
     * @dev Uses delegatecall - implementation runs in proxy's storage context
     */
    fallback() external payable {
        address impl = implementation;
        require(impl != address(0), "Implementation not set");
        
        assembly {
            // Copy calldata to memory
            calldatacopy(0, 0, calldatasize())
            
            // Delegatecall to implementation
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            
            // Copy return data
            returndatacopy(0, 0, returndatasize())
            
            // Return or revert based on result
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    
    receive() external payable {}
}
