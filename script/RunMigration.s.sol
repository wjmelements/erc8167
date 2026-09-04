pragma solidity ^0.8.36;

import {Script} from "forge-std/Script.sol";

import {Migrate} from "src/interfaces/Migrate.sol";

contract RunMigrationScript is Script {
    function run(address proxy, address migration) public {
        vm.startBroadcast();

        Migrate(proxy).migrate(migration);

        vm.stopBroadcast();
    }
}
