pragma solidity ^0.8.36;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {IERC8167} from "../src/interfaces/IERC8167.sol";
import {AbiCheats} from "../src/lib/AbiCheats.sol";

contract AbiCheatsTest is Test {
    using AbiCheats for Vm;

    function testGetSelectors() public view {
        bytes4[] memory selectors = vm.getSelectors("out/IERC8167.sol/IERC8167.json");
        assertEq(selectors.length, 2);
        assertEq(selectors[0], IERC8167.implementation.selector);
        assertEq(selectors[1], IERC8167.selectors.selector);
    }
}
