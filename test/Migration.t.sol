pragma solidity ^0.8.36;

import {Test} from "forge-std/Test.sol";

import {SetDelegateOperation, SetDelegateOperationLibrary} from "../src/lib/Migration.sol";

contract ValidationHarness {
    function validate(SetDelegateOperation[] memory operations) external pure {
        SetDelegateOperationLibrary.validate(operations);
    }
}

contract MigrationTest is Test {
    function testConcatBothNonEmpty() public pure {
        SetDelegateOperation[] memory a = _ops(3, 1);
        SetDelegateOperation[] memory b = _ops(2, 100);

        SetDelegateOperation[] memory result = SetDelegateOperationLibrary.concat(a, b);

        assertEq(result.length, 5);
        _assertOpsEq(result, 0, a, 0, 3);
        _assertOpsEq(result, 3, b, 0, 2);
    }

    function testConcatEmptyFirst() public pure {
        SetDelegateOperation[] memory a = _ops(0, 1);
        SetDelegateOperation[] memory b = _ops(2, 100);

        SetDelegateOperation[] memory result = SetDelegateOperationLibrary.concat(a, b);

        assertEq(result.length, 2);
        _assertOpsEq(result, 0, b, 0, 2);
    }

    function testConcatEmptySecond() public pure {
        SetDelegateOperation[] memory a = _ops(3, 1);
        SetDelegateOperation[] memory b = _ops(0, 100);

        SetDelegateOperation[] memory result = SetDelegateOperationLibrary.concat(a, b);

        assertEq(result.length, 3);
        _assertOpsEq(result, 0, a, 0, 3);
    }

    function testConcatBothEmpty() public pure {
        SetDelegateOperation[] memory a = _ops(0, 1);
        SetDelegateOperation[] memory b = _ops(0, 100);

        SetDelegateOperation[] memory result = SetDelegateOperationLibrary.concat(a, b);

        assertEq(result.length, 0);
    }

    function testFlattenMultiple() public pure {
        SetDelegateOperation[][] memory operations = new SetDelegateOperation[][](3);
        operations[0] = _ops(2, 1);
        operations[1] = _ops(0, 50);
        operations[2] = _ops(3, 100);

        SetDelegateOperation[] memory flat = SetDelegateOperationLibrary.flatten(operations);

        assertEq(flat.length, 5);
        _assertOpsEq(flat, 0, operations[0], 0, 2);
        _assertOpsEq(flat, 2, operations[2], 0, 3);
    }

    function testFlattenEmptyOuter() public pure {
        SetDelegateOperation[][] memory operations = new SetDelegateOperation[][](0);

        SetDelegateOperation[] memory flat = SetDelegateOperationLibrary.flatten(operations);

        assertEq(flat.length, 0);
    }

    function testFlattenSingleInner() public pure {
        SetDelegateOperation[][] memory operations = new SetDelegateOperation[][](1);
        operations[0] = _ops(4, 1);

        SetDelegateOperation[] memory flat = SetDelegateOperationLibrary.flatten(operations);

        assertEq(flat.length, 4);
        _assertOpsEq(flat, 0, operations[0], 0, 4);
    }

    function testFlattenAllEmptyInners() public pure {
        SetDelegateOperation[][] memory operations = new SetDelegateOperation[][](3);
        operations[0] = _ops(0, 1);
        operations[1] = _ops(0, 2);
        operations[2] = _ops(0, 3);

        SetDelegateOperation[] memory flat = SetDelegateOperationLibrary.flatten(operations);

        assertEq(flat.length, 0);
    }

    function testValidate() public {
        ValidationHarness harness = new ValidationHarness();

        SetDelegateOperation[] memory operations = _ops(1, 0);
        harness.validate(operations);
        operations = _ops(2, 0);
        harness.validate(operations);

        SetDelegateOperation[][] memory duplicates = new SetDelegateOperation[][](2);
        duplicates[0] = _ops(1, 0);
        duplicates[1] = _ops(3, 0);
        operations = SetDelegateOperationLibrary.flatten(duplicates);

        vm.expectRevert(
            abi.encodeWithSelector(SetDelegateOperationLibrary.DuplicatedSelector.selector, duplicates[0][0].selector)
        );
        harness.validate(operations);

        duplicates[0] = _ops(3, 0);
        duplicates[1] = _ops(3, 2);
        operations = SetDelegateOperationLibrary.flatten(duplicates);
        vm.expectRevert(
            abi.encodeWithSelector(SetDelegateOperationLibrary.DuplicatedSelector.selector, duplicates[0][2].selector)
        );
        harness.validate(operations);
    }

    function _ops(uint256 count, uint256 seed) internal pure returns (SetDelegateOperation[] memory result) {
        result = new SetDelegateOperation[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = SetDelegateOperation({
                selector: bytes4(keccak256(abi.encode("selector", seed + i))),
                delegate: address(uint160(uint256(keccak256(abi.encode("delegate", seed, i)))))
            });
        }
    }

    function _assertOpsEq(
        SetDelegateOperation[] memory actual,
        uint256 actualOffset,
        SetDelegateOperation[] memory expected,
        uint256 expectedOffset,
        uint256 count
    ) internal pure {
        for (uint256 i = 0; i < count; i++) {
            assertEq(actual[actualOffset + i].selector, expected[expectedOffset + i].selector);
            assertEq(actual[actualOffset + i].delegate, expected[expectedOffset + i].delegate);
        }
    }
}
