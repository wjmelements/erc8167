pragma solidity ^0.8.36;

/// @dev keccak256(abi.encode(uint256(keccak256("erc8167.storage.delegates")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant DELEGATES_STORAGE_LOCATION = 0xf27774d37a8b3bf2306f60b561e4e8ec22cfb23796f1f777608c0e466ef52600;

/// @notice Solidity mirror of the ERC-8167 proxy's storage layout.
library ProxyStorage {
    /// @custom:storage-location erc7201:erc8167.storage.delegates
    struct DelegatesStorage {
        mapping(bytes4 selector => address delegate) delegates;
    }

    function delegateStorageKey(bytes4 selector) internal pure returns (bytes32 storageKey) {
        storageKey = keccak256(abi.encode(selector, DELEGATES_STORAGE_LOCATION));
    }

    function get() internal pure returns (DelegatesStorage storage $) {
        assembly ("memory-safe") {
            $.slot := DELEGATES_STORAGE_LOCATION
        }
    }
}
