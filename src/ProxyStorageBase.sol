pragma solidity ^0.8.30;

contract ProxyStorageBase {
    mapping(bytes4 selector => address delegate) internal delegates;
}
