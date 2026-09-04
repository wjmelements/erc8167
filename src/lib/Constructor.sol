pragma solidity ^0.8.36;

bytes constant UNIVERSAL_CONSTRUCTOR = hex"600b380380600b3d393df3";
uint256 constant UNIVERSAL_CONSTRUCTOR_LENGTH = 11;

library Constructor {
    function create(bytes memory initcode) internal returns (address account) {
        assembly ("memory-safe") {
            account := create(0, add(0x20, initcode), mload(initcode))
        }
        require(account != address(0));
    }

    function deploy(bytes memory deployedBytecode) internal returns (address account) {
        account = create(abi.encodePacked(UNIVERSAL_CONSTRUCTOR, deployedBytecode));
    }
}
