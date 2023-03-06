// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import "../src/support/SupportsDODO.sol";
import "forge-std/Test.sol";

contract SupportsDODOScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new SupportsDODO(
            0xDd29a69462a08006Fda068D090b44B045958C5B7,
                0x3cE004b7C03451188529E38581b28A3C5fa8BB77,
                0x415DF0A4Ac25C2D480Fd471914893f287276b63A
        );
        console2.log("deploy USDO");
        vm.stopBroadcast();
    }
}
