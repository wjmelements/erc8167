pragma solidity ^0.8.36;

import {Constructor, UNIVERSAL_CONSTRUCTOR_LENGTH} from "./Constructor.sol";
import {SET_DELEGATE_SIZE, SetDelegate} from "./SetDelegate.sol";

struct SetDelegateOperation {
    bytes4 selector;
    address delegate;
}

library SetDelegateOperationLibrary {
    function concat(SetDelegateOperation[] memory a, SetDelegateOperation[] memory b)
        internal
        pure
        returns (SetDelegateOperation[] memory result)
    {
        assembly ("memory-safe") {
            let aLen := mload(a)
            let bLen := mload(b)
            result := mload(0x40)
            mstore(result, add(aLen, bLen))
            let aBytes := shl(5, aLen)
            let bBytes := shl(5, bLen)
            let dst := add(result, 0x20)
            mcopy(dst, add(a, 0x20), aBytes)
            dst := add(dst, aBytes)
            mcopy(dst, add(b, 0x20), bBytes)
            mstore(0x40, add(dst, bBytes))
        }
    }

    function flatten(SetDelegateOperation[][] memory operations)
        internal
        pure
        returns (SetDelegateOperation[] memory flat)
    {
        assembly ("memory-safe") {
            let opsLen := mload(operations)
            let opsPtr := add(operations, 0x20)

            let totalLen := 0
            for { let i := 0 } lt(i, opsLen) { i := add(i, 1) } {
                totalLen := add(totalLen, mload(mload(add(opsPtr, shl(5, i)))))
            }

            flat := mload(0x40)
            mstore(flat, totalLen)
            let dst := add(flat, 0x20)
            for { let i := 0 } lt(i, opsLen) { i := add(i, 1) } {
                let operation := mload(add(opsPtr, shl(5, i)))
                let operationBytes := shl(5, mload(operation))
                mcopy(dst, add(operation, 0x20), operationBytes)
                dst := add(dst, operationBytes)
            }
            mstore(0x40, dst)
        }
    }

    error DuplicatedSelector(bytes4 selector);

    /// @notice Verifies that selector is not duplicated within the list
    function validate(SetDelegateOperation[] memory operations) internal pure {
        for (uint256 i = 1; i < operations.length; i++) {
            for (uint256 j; j < i; j++) {
                require(operations[i].selector != operations[j].selector, DuplicatedSelector(operations[i].selector));
            }
        }
    }
}

library Migration {
    using Constructor for bytes;
    using SetDelegate for bytes4;

    // TODO can optimize codesize by grouping by implementation and reusing event

    function createMigration(bytes4[] memory selectors, address[] memory delegates)
        internal
        returns (address migration)
    {
        bytes memory initcode = new bytes(SET_DELEGATE_SIZE * selectors.length + UNIVERSAL_CONSTRUCTOR_LENGTH);

        uint256 dst;
        assembly ("memory-safe") {
            dst := add(0x20, initcode)
            mstore(dst, shl(168, 0x600b380380600b3d393df3))
            dst := add(UNIVERSAL_CONSTRUCTOR_LENGTH, dst)
        }
        for (uint256 i = 0; i < selectors.length; i++) {
            bytes memory operation = selectors[i].setDelegateBytecode(delegates[i]);
            assembly ("memory-safe") {
                mcopy(dst, add(operation, 0x20), SET_DELEGATE_SIZE)
                dst := add(SET_DELEGATE_SIZE, dst)
            }
        }
        return initcode.create();
    }

    function createMigration(SetDelegateOperation[] memory operations) internal returns (address migration) {
        bytes memory initcode = new bytes(SET_DELEGATE_SIZE * operations.length + UNIVERSAL_CONSTRUCTOR_LENGTH);

        uint256 dst;
        assembly ("memory-safe") {
            dst := add(0x20, initcode)
            mstore(dst, shl(168, 0x600b380380600b3d393df3))
            dst := add(UNIVERSAL_CONSTRUCTOR_LENGTH, dst)
        }
        for (uint256 i = 0; i < operations.length; i++) {
            SetDelegateOperation memory operation = operations[i];
            bytes memory operationCode = operation.selector.setDelegateBytecode(operation.delegate);
            assembly ("memory-safe") {
                mcopy(dst, add(operationCode, 0x20), SET_DELEGATE_SIZE)
                dst := add(SET_DELEGATE_SIZE, dst)
            }
        }
        return initcode.create();
    }
}
