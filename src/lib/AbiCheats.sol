pragma solidity ^0.8.36;

import {Vm} from "forge-std/Vm.sol";

library AbiCheats {
    /// @dev Reads every external/public function selector out of a forge build artifact's
    ///      `methodIdentifiers`, so migrations don't need to hardcode a contract's ABI by hand.
    function getSelectors(Vm vm, string memory artifactPath) internal view returns (bytes4[] memory selectors) {
        // forge-lint: disable-next-line(unsafe-cheatcode)
        string memory json = vm.readFile(artifactPath);
        string[] memory signatures = vm.parseJsonKeys(json, ".methodIdentifiers");
        selectors = new bytes4[](signatures.length);
        for (uint256 i = 0; i < signatures.length; i++) {
            selectors[i] = bytes4(keccak256(bytes(signatures[i])));
        }
    }
}
