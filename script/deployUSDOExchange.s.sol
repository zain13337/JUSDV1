/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0*/
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import "../src/Impl/JUSDExchange.sol";

contract JUSDExchangeScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new JUSDExchange(
        // _USDC
        0xDd29a69462a08006Fda068D090b44B045958C5B7,
        // _JUSD
        0x834D14F87700e5fFc084e732c7381673133cdbcC);
        console2.log("deploy JUSDExchange");
        vm.stopBroadcast();
    }
}
