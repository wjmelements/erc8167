pragma solidity ^0.8.36;

import {IERC8167} from "../interfaces/IERC8167.sol";
import {ProxyStorage} from "./ProxyStorage.sol";

contract SelfUninstalling {
    /// @notice Uninstalls the function from dispatch, unless the body reverts.
    /// @dev The delete happens first to prevent reentrancy.
    modifier selfUninstalling() {
        bytes4 sig = msg.sig;
        delete ProxyStorage.get().delegates[sig];
        emit IERC8167.SelectorDelegated(sig, address(0));
        _;
    }
}
