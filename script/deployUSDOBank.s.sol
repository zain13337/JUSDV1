/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0*/
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import "../src/Impl/JUSDBank.sol";

contract JUSDBankScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new JUSDBank(
        // maxReservesAmount_
            10,
            // _insurance
        0xc3477972a62c4Ef3eDE0134653a1a09835ca9AE5,
        // JUSD
        0x834D14F87700e5fFc084e732c7381673133cdbcC,
        // JOJODealer
        0xFfD3B82971dAbccb3219d16b6EB2DB134bf55300,
        // maxBorrowAmountPerAccount_
            100000000000,
        // maxBorrowAmount_
            1000000000000,
        // borrowFeeRate_
                0,
        // usdc
                0xDd29a69462a08006Fda068D090b44B045958C5B7);
        console2.log("deploy JUSDBank");
        vm.stopBroadcast();
    }
}
