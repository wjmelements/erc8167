pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {Bootstrap} from "../src/interfaces/Bootstrap.sol";
import {IERC8109Minimal} from "../src/interfaces/IERC8109Minimal.sol";

contract ProxyTest is Test {
    address internal proxy;
    address internal bootstrapImpl;

    function setUp() public {
        proxy = deployCode("out/Proxy.constructor.evm/Proxy.constructor.json");
        bootstrapImpl = vm.computeCreateAddress(proxy, 1);
    }

    function testBootstrapDeployed() public view {
        assertEq(bootstrapImpl.code.length, 93);
    }

    function testFunctionNotFound() public {
        vm.expectRevert(
            abi.encodeWithSelector(IERC8109Minimal.FunctionNotFound.selector, IERC8109Minimal.facetAddress.selector)
        );
        IERC8109Minimal(proxy).facetAddress(Bootstrap.configure.selector);
    }

    function testBootstrapConfigureUnauthorized() public {
        address unauthorized = makeAddr("thief");
        vm.expectRevert(abi.encodeWithSelector(Bootstrap.Unauthorized.selector, unauthorized));
        vm.prank(unauthorized);
        Bootstrap(proxy).configure(Bootstrap.configure.selector, address(this));
    }

    function testBootstrapConfigureIntrospect() public {
        address facetAddressImpl = deployCode("out/facetAddress.evm/facetAddress.json");
        assertEq(facetAddressImpl.code.length, 15);

        vm.expectEmit(proxy);
        emit IERC8109Minimal.SetDiamondFacet(IERC8109Minimal.facetAddress.selector, facetAddressImpl);
        Bootstrap(proxy).configure(IERC8109Minimal.facetAddress.selector, facetAddressImpl);

        assertEq(IERC8109Minimal(proxy).facetAddress(IERC8109Minimal.facetAddress.selector), facetAddressImpl);
        assertEq(IERC8109Minimal(proxy).facetAddress(Bootstrap.configure.selector), bootstrapImpl);

        vm.expectEmit(proxy);
        emit IERC8109Minimal.SetDiamondFacet(Bootstrap.configure.selector, address(0));
        Bootstrap(proxy).configure(Bootstrap.configure.selector, address(0));

        assertEq(IERC8109Minimal(proxy).facetAddress(Bootstrap.configure.selector), address(0));

        vm.expectRevert(abi.encodeWithSelector(IERC8109Minimal.FunctionNotFound.selector, Bootstrap.configure.selector));
        Bootstrap(proxy).configure(IERC8109Minimal.facetAddress.selector, address(0));
    }
}
