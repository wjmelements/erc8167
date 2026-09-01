pragma solidity ^0.8.30;

interface Implementation {
    function implementation(bytes4 selector) external view returns (address delegate);
}
