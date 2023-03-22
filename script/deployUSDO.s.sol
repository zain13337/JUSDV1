// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import "../src/token/JUSD.sol";
import "forge-std/Test.sol";

contract JUSDScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new JUSD(6);
        console2.log("deploy JUSD");
        vm.stopBroadcast();
    }
}
