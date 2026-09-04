pragma solidity ^0.8.36;

import {Constructor, UNIVERSAL_CONSTRUCTOR_LENGTH} from "./Constructor.sol";
import {SET_DELEGATE_SIZE, SetDelegate} from "./SetDelegate.sol";

struct SetDelegateOperation {
    bytes4 selector;
    address delegate;
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
