pragma solidity ^0.8.30;

interface IERC8167 {
    error FunctionNotFound(bytes4 selector);

    event SetDelegate(bytes4 indexed selector, address indexed delegate);

    function implementation(bytes4 selector) external view returns (address);

    function selectors() external view returns (bytes4[] memory);
}
