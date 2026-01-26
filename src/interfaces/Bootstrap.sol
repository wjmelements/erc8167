pragma solidity ^0.8.30;

interface Bootstrap {
    error Unauthorized(address);
    function configure(bytes4 selector, address delegate) external;
}
