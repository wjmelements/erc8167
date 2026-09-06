pragma solidity ^0.8.36;

import {Test} from "forge-std/Test.sol";

import {Bootstrap} from "../src/interfaces/Bootstrap.sol";
import {Migrate} from "../src/interfaces/Migrate.sol";
import {IERC8167} from "../src/interfaces/IERC8167.sol";
import {Migration, SetDelegateOperation} from "../src/lib/Migration.sol";

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
        assertEq(bootstrapImpl.code.length, 126);
    }

    function testBootstrapBytecode() public view {
        bytes memory standalone = vm.getDeployedCode("out/Bootstrap.evm/Bootstrap.json");
        bytes memory deployed = bootstrapImpl.code;
        assertEq(deployed.length, standalone.length);

        assertEq(uint8(deployed[0]), uint8(standalone[0]));
        for (uint256 i = 21; i < standalone.length; i++) {
            assertEq(deployed[i], standalone[i]);
        }
        // sets the immutable owner address
        assertEq(address(bytes20(_slice20(deployed, 1))), address(this));
    }

    function _slice20(bytes memory b, uint256 start) private pure returns (bytes20 out) {
        assembly {
            out := mload(add(add(b, 0x20), start))
        }
    }

    function testConstructorEvents() public {
        address expectedProxy = vm.computeCreateAddress(address(this), 2);
        address expectedBootstrapImpl = vm.computeCreateAddress(expectedProxy, 1);

        vm.expectEmit(expectedProxy);
        emit IERC8167.SelectorDelegated(Bootstrap.configure.selector, expectedBootstrapImpl);

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
        address implementationImpl = deployCode("out/Implementation.evm/Implementation.json");
        assertEq(implementationImpl.code.length, 49);

        vm.expectEmit(proxy);
        emit IERC8167.SelectorDelegated(IERC8167.implementation.selector, implementationImpl);
        Bootstrap(proxy).configure(IERC8167.implementation.selector, implementationImpl);

        assertEq(IERC8167(proxy).implementation(IERC8167.implementation.selector), implementationImpl);
        assertEq(IERC8167(proxy).implementation(Bootstrap.configure.selector), bootstrapImpl);

        vm.expectEmit(proxy);
        emit IERC8167.SelectorDelegated(Bootstrap.configure.selector, address(0));
        Bootstrap(proxy).configure(Bootstrap.configure.selector, address(0));

        assertEq(IERC8167(proxy).implementation(Bootstrap.configure.selector), address(0));

        vm.expectRevert(abi.encodeWithSelector(IERC8167.FunctionNotFound.selector, Bootstrap.configure.selector));
        Bootstrap(proxy).configure(IERC8167.implementation.selector, address(0));
    }

    function create(bytes memory initcode) internal returns (address account) {
        assembly ("memory-safe") {
            account := create(0, add(0x20, initcode), mload(initcode))
        }
        assertNotEq(account, address(0));
    }

    function testMigrate() public {
        address migrateImpl = deployCode("out/Migrate.constructor.evm/Migrate.constructor.json");
        Bootstrap(proxy).configure(Migrate.migrate.selector, migrateImpl);

        SetDelegateOperation[] memory operations = new SetDelegateOperation[](1);
        operations[0].selector = Bootstrap.configure.selector;
        operations[0].delegate = address(0);
        address removeConfigureMigration = Migration.createMigration(operations);

        address unauthorized = makeAddr("thief");
        vm.prank(unauthorized);
        vm.expectRevert(abi.encodeWithSelector(Migrate.Unauthorized.selector, unauthorized));
        Migrate(proxy).migrate(removeConfigureMigration);

        vm.expectEmit(proxy);
        emit Migrate.DiamondDelegateCall(removeConfigureMigration, "");
        vm.expectEmit(proxy);
        emit IERC8167.SelectorDelegated(Bootstrap.configure.selector, address(0));
        Migrate(proxy).migrate(removeConfigureMigration);

        vm.expectRevert(abi.encodeWithSelector(IERC8167.FunctionNotFound.selector, Bootstrap.configure.selector));
        Bootstrap(proxy).configure(Migrate.migrate.selector, address(0));
    }
}
