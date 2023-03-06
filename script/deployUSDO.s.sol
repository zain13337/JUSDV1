// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import "../src/token/USDO.sol";
import "forge-std/Test.sol";

contract USDOScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new USDO(6);
        console2.log("deploy USDO");
        vm.stopBroadcast();
    }
}
