// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import "../test/mocks/TestERC20.sol";
import "forge-std/Test.sol";

contract WETHScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new TestERC20("JUSD", "JUSD", 6);
        console2.log("deploy JUSD");
        vm.stopBroadcast();
    }
}
