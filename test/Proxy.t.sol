pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";

import { Bootstrap } from "../src/interfaces/Bootstrap.sol";
import { IERC8109Minimal } from "../src/interfaces/IERC8109Minimal.sol";

contract ProxyTest is Test {

    bytes4 private constant SELECTOR = 0x12345678;

    address proxy;
    address bootstrap;

    function setUp() public {
        proxy = deployCode("out/Proxy.constructor.evm/Proxy.json");
        bootstrap = vm.computeCreateAddress(proxy, 1);
    }

    function testBootstrapDeployed() public {
        assertEq(bootstrap.code.length, 55);
    }

    function testRevert() public {
        vm.expectRevert(abi.encodeWithSelector(IERC8109Minimal.FunctionNotFound.selector, SELECTOR));
        proxy.call(abi.encodeWithSelector(SELECTOR));
    }

    function testBootstrapConfigureRequiresOwner() public {
        address unauthorized = makeAddr("thief");
        vm.expectRevert(abi.encodeWithSelector(Bootstrap.Unauthorized.selector, unauthorized));
        vm.prank(unauthorized);
        Bootstrap(proxy).configure(Bootstrap.configure.selector, address(this));
    }

    function testBootstrapConfigureIntrospect() public {
        address facetAddressImpl = deployCode("out/facetAddress.evm/facetAddress.json");
        Bootstrap(proxy).configure(IERC8109Minimal.facetAddress.selector, facetAddressImpl);
        assertEq(IERC8109Minimal(proxy).facetAddress(IERC8109Minimal.facetAddress.selector), facetAddressImpl);
        assertEq(IERC8109Minimal(proxy).facetAddress(Bootstrap.configure.selector), bootstrap);
    }
}
