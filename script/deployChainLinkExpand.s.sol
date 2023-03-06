// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import "../test/mocks/MockChainLink500.sol";
import "forge-std/Test.sol";
import "../test/mocks/MockChainLinkBadDebt.sol";

contract ChainLinkMockScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new MockChainLinkBadDebt();
        console2.log("deploy mockChainLinkBadDebt");
        vm.stopBroadcast();
    }
}
