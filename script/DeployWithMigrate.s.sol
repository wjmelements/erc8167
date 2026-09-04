pragma solidity ^0.8.36;

import {Script} from "forge-std/Script.sol";

import {Bootstrap} from "src/interfaces/Bootstrap.sol";
import {IERC8167} from "src/interfaces/IERC8167.sol";
import {Migrate} from "src/interfaces/Migrate.sol";

contract DeployWithMigrateScript is Script {
    function run() public returns (IERC8167 proxy, Bootstrap bootstrapImplementation, Migrate migrateImplementation) {
        vm.startBroadcast();
        address proxyAddress = vm.deployCode("out/Proxy.constructor.evm/Proxy.constructor.json");

        address migrateImpl = vm.deployCode("out/Migrate.constructor.evm/Migrate.constructor.json");
        Bootstrap(proxyAddress).configure(Migrate.migrate.selector, migrateImpl);

        vm.stopBroadcast();

        address bootstrapper = vm.computeCreateAddress(proxyAddress, 1);

        return (IERC8167(proxyAddress), Bootstrap(bootstrapper), Migrate(migrateImpl));
    }
}
