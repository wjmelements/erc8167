pragma solidity ^0.8.36;

import {Test} from "forge-std/Test.sol";

import {Bootstrap} from "../src/interfaces/Bootstrap.sol";
import {IERC8167} from "../src/interfaces/IERC8167.sol";
import {SelfUninstalling} from "../src/lib/SelfUninstalling.sol";

contract InitializationFacet is SelfUninstalling {
    uint256 private counter;

    function getCounter() external view returns (uint256) {
        return counter;
    }

    function incrementOnce() external selfUninstalling returns (bool) {
        counter++;
        return true;
    }

    function tryReentry(uint256 i) external selfUninstalling returns (uint256 sum) {
        if (i == 0) {
            return 0;
        }
        return i + this.tryReentry(i - 1);
    }
}

contract SelfUninstallingTest is Test {
    function testSelfUninstalling() public {
        address proxy = deployCode("out/Proxy.constructor.evm/Proxy.constructor.json");
        address facet = address(new InitializationFacet());

        vm.expectEmit(proxy);
        emit IERC8167.SelectorDelegated(InitializationFacet.getCounter.selector, facet);

        Bootstrap(proxy).configure(InitializationFacet.getCounter.selector, facet);

        vm.expectEmit(proxy);
        emit IERC8167.SelectorDelegated(InitializationFacet.incrementOnce.selector, facet);
        Bootstrap(proxy).configure(InitializationFacet.incrementOnce.selector, facet);

        assertEq(InitializationFacet(proxy).getCounter(), 0);

        vm.expectEmit(proxy);
        emit IERC8167.SelectorDelegated(InitializationFacet.incrementOnce.selector, address(0));
        assertTrue(InitializationFacet(proxy).incrementOnce());

        assertEq(InitializationFacet(proxy).getCounter(), 1);

        vm.expectRevert(
            abi.encodeWithSelector(IERC8167.FunctionNotFound.selector, InitializationFacet.incrementOnce.selector)
        );
        InitializationFacet(proxy).incrementOnce();

        vm.expectEmit(proxy);
        emit IERC8167.SelectorDelegated(InitializationFacet.tryReentry.selector, facet);
        Bootstrap(proxy).configure(InitializationFacet.tryReentry.selector, facet);

        vm.expectEmit(proxy);
        emit IERC8167.SelectorDelegated(InitializationFacet.tryReentry.selector, address(0));
        assertEq(InitializationFacet(proxy).tryReentry(0), 0);

        vm.expectEmit(proxy);
        emit IERC8167.SelectorDelegated(InitializationFacet.tryReentry.selector, facet);
        Bootstrap(proxy).configure(InitializationFacet.tryReentry.selector, facet);

        // facet can do this, but not proxy
        vm.expectEmit(facet);
        emit IERC8167.SelectorDelegated(InitializationFacet.tryReentry.selector, address(0));
        vm.expectEmit(facet);
        emit IERC8167.SelectorDelegated(InitializationFacet.tryReentry.selector, address(0));
        vm.expectEmit(facet);
        emit IERC8167.SelectorDelegated(InitializationFacet.tryReentry.selector, address(0));
        vm.expectEmit(facet);
        emit IERC8167.SelectorDelegated(InitializationFacet.tryReentry.selector, address(0));
        assertEq(InitializationFacet(facet).tryReentry(3), 6);

        // proxy cannot reenter uninstalled
        for (uint256 i = 1; i < 4; i++) {
            vm.expectRevert(
                abi.encodeWithSelector(IERC8167.FunctionNotFound.selector, InitializationFacet.tryReentry.selector)
            );
            InitializationFacet(proxy).tryReentry(i);
        }

        vm.expectEmit(proxy);
        emit IERC8167.SelectorDelegated(InitializationFacet.tryReentry.selector, address(0));
        assertEq(InitializationFacet(proxy).tryReentry(0), 0);
    }
}
