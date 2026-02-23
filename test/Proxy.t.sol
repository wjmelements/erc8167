pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {Bootstrap} from "../src/interfaces/Bootstrap.sol";
import {IERC8167} from "../src/interfaces/IERC8167.sol";

contract ProxyTest is Test {
    address internal proxy;
    address internal bootstrapImpl;

    function deployProxy() internal returns (address) {
        return deployCode("out/Proxy.constructor.evm/Proxy.constructor.json");
    }

    function setUp() public {
        proxy = deployProxy();
        bootstrapImpl = vm.computeCreateAddress(proxy, 1);
    }

    function testBootstrapDeployed() public view {
        assertEq(bootstrapImpl.code.length, 93);
    }

    function testConstructorEvents() public {
        address expectedProxy = vm.computeCreateAddress(address(this), 2);
        address expectedBootstrapImpl = vm.computeCreateAddress(expectedProxy, 1);

        vm.expectEmit(expectedProxy);
        emit IERC8167.SetDelegate(Bootstrap.configure.selector, expectedBootstrapImpl);

        address actualProxy = deployProxy();

        assertEq(expectedProxy, actualProxy);
    }

    function testFunctionNotFound() public {
        vm.expectRevert(abi.encodeWithSelector(IERC8167.FunctionNotFound.selector, IERC8167.implementation.selector));
        IERC8167(proxy).implementation(Bootstrap.configure.selector);
    }

    function testBootstrapConfigureUnauthorized() public {
        address unauthorized = makeAddr("thief");
        vm.expectRevert(abi.encodeWithSelector(Bootstrap.Unauthorized.selector, unauthorized));
        vm.prank(unauthorized);
        Bootstrap(proxy).configure(Bootstrap.configure.selector, address(this));
    }

    function testBootstrapConfigureIntrospect() public {
        address implementationImpl = deployCode("out/implementation.evm/implementation.json");
        assertEq(implementationImpl.code.length, 15);

        vm.expectEmit(proxy);
        emit IERC8167.SetDelegate(IERC8167.implementation.selector, implementationImpl);
        Bootstrap(proxy).configure(IERC8167.implementation.selector, implementationImpl);

        assertEq(IERC8167(proxy).implementation(IERC8167.implementation.selector), implementationImpl);
        assertEq(IERC8167(proxy).implementation(Bootstrap.configure.selector), bootstrapImpl);

        vm.expectEmit(proxy);
        emit IERC8167.SetDelegate(Bootstrap.configure.selector, address(0));
        Bootstrap(proxy).configure(Bootstrap.configure.selector, address(0));

        assertEq(IERC8167(proxy).implementation(Bootstrap.configure.selector), address(0));

        vm.expectRevert(abi.encodeWithSelector(IERC8167.FunctionNotFound.selector, Bootstrap.configure.selector));
        Bootstrap(proxy).configure(IERC8167.implementation.selector, address(0));
    }
}
