pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {ProxyStorageBase} from "../src/ProxyStorageBase.sol";
import {Bootstrap} from "../src/interfaces/Bootstrap.sol";
import {IERC8167} from "../src/interfaces/IERC8167.sol";

contract ProxyStorageView is ProxyStorageBase {
    function implementation(bytes4 selector) public view returns (address delegate) {
        return adminStorage().selectorInfo[selector].delegate;
    }
}

contract ProxyStorageBaseTest is Test {
    address internal proxy;

    function setUp() public {
        proxy = deployCode("out/Proxy.constructor.evm/Proxy.constructor.json");
    }

    function testStorage() public {
        ProxyStorageView storageView = new ProxyStorageView();
        Bootstrap(proxy).configure(IERC8167.implementation.selector, address(storageView));
        assertEq(IERC8167(proxy).implementation(IERC8167.implementation.selector), address(storageView));
    }
}
