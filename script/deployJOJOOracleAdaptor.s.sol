// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import "../src/Impl/JOJOOracleAdaptor.sol";
import "forge-std/Test.sol";

contract JOJOOracleAdaptorScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new JOJOOracleAdaptor(
            0x6550bc2301936011c1334555e62A87705A81C12C ,
        10, 86400
        );
        console2.log("deploy JOJOOracleAdaptor");
        vm.stopBroadcast();
    }
}
