pragma solidity ^0.8.30;

interface IERC8109Minimal {
    error FunctionNotFound(bytes4 selector);
    function facetAddress(bytes4 selector) external view returns (address);
}
