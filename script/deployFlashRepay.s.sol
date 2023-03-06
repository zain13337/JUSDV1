/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0*/
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import "../src/Impl/FlashLoanRepay.sol";

contract FlashRepayScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new FlashLoanRepay(
        // _usdoBank
            0x77E5EE568C84986772eeb461Ae6744B76e37b802,
        // _usdoExchange
                0x8Dd79B16AA7ab776CE8aA15D67c7C04cAFe0f4de,
        // _USDC
            0xDd29a69462a08006Fda068D090b44B045958C5B7,
        // _USDO
            0x834D14F87700e5fFc084e732c7381673133cdbcC);
        console2.log("deploy FlashLoanRepay");
        vm.stopBroadcast();
    }
}
