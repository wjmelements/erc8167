pragma solidity ^0.8.36;

interface Migrate {
    error Unauthorized(address);
    function migrate(address migration) external;
}
