pragma solidity ^0.8.36;

interface Migrate {
    event DiamondDelegateCall(address indexed delegate, bytes delegateCalldata);

    error Unauthorized(address);
    function migrate(address migration) external;
}
