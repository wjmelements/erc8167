pragma solidity ^0.8.36;

import {IERC8167} from "../interfaces/IERC8167.sol";
import {DELEGATES_STORAGE_LOCATION} from "./ProxyStorage.sol";

uint256 constant SET_DELEGATE_SIZE = 100;

library SetDelegate {
    function setDelegateBytecode(bytes4 selector, address implementation) internal pure returns (bytes memory) {
        bytes32 storageKey;
        assembly ("memory-safe") {
            mstore(0, selector)
            mstore(32, DELEGATES_STORAGE_LOCATION)
            storageKey := keccak256(0, 64)
        }
        return abi.encodePacked(
            bytes1(0x73),
            implementation, // PUSH20 implementation
            bytes1(0x80), // DUP1
            bytes1(0x63),
            selector, // PUSH4 selector
            bytes3(0x60e01b), // PUSH1 0xe0 SHL
            bytes1(0x7f),
            IERC8167.SelectorDelegated.selector, // PUSH32 event SelectorDelegated
            bytes3(0x5f5fa3), // PUSH0 PUSH0 LOG3
            bytes1(0x7f),
            storageKey, // PUSH32 storageKey
            bytes1(0x55) // SSTORE
        );
    }
}
