// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "./USDOBankInit.t.sol";
import "../../src/Impl/FlashLoanLiquidate.sol";

contract USDOBankClearReserveTest is USDOBankInitTest {
    /// @notice user borrow usdo account is not safe
    function testClearReserve() public {
        mockToken1.transfer(alice, 10e18);
        mockToken2.transfer(bob, 10e8);

        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        vm.warp(1000);
        usdoBank.deposit(alice, address(mockToken1), 10e18, alice);
        vm.warp(2000);
        usdoBank.borrow(3000e6, alice, false);
        vm.stopPrank();
        //mocktoken1 relist
        usdoBank.delistReserve(address(mockToken1));
        //bob liquidate alice
        vm.startPrank(bob);
        FlashLoanLiquidate flashLoanLiquidate = new FlashLoanLiquidate(
            address(usdoBank),
            address(usdoExchange),
            address(USDC),
            address(usdo),
            insurance
        );
        bytes memory data = dodo.getSwapData(10e18, address(mockToken1));
        bytes memory param = abi.encode(dodo, dodo, address(bob), data);
        bytes memory afterParam = abi.encode(address(flashLoanLiquidate), param);

        DataTypes.LiquidateData memory liq = usdoBank.liquidate(alice, address(mockToken1), bob, 10e18, afterParam, 0);

        // logs

        uint256 bobDeposit = usdoBank.getDepositBalance(address(mockToken1), bob);
        uint256 aliceDeposit = usdoBank.getDepositBalance(address(mockToken1), alice);
        uint256 bobBorrow = usdoBank.getBorrowBalance(bob);
        uint256 aliceBorrow = usdoBank.getBorrowBalance(alice);
        uint256 insuranceUSDC = IERC20(USDC).balanceOf(insurance);
        uint256 aliceUSDC = IERC20(USDC).balanceOf(alice);
        uint256 bobUSDC = IERC20(USDC).balanceOf(bob);
        console.log("liquidate amount", liq.actualCollateral);
        console.log("bob deposit", bobDeposit);
        console.log("alice deposit", aliceDeposit);
        console.log("bob borrow", bobBorrow);
        console.log("alice borrow", aliceBorrow);
        console.log("bob usdc", bobUSDC);
        console.log("alice usdc", aliceUSDC);
        console.log("insurance balance", insuranceUSDC);
        vm.stopPrank();
    }

    function testClearMock2() public {
        mockToken1.transfer(alice, 10e18);
        mockToken2.transfer(alice, 1e8);

        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        usdoBank.deposit(alice, address(mockToken1), 10e18, alice);
        usdoBank.borrow(3000e6, alice, false);
        vm.stopPrank();

        usdoBank.delistReserve(address(mockToken1));

        vm.startPrank(alice);
        mockToken2.approve(address(usdoBank), 1e8);
        usdoBank.deposit(alice, address(mockToken2), 1e8, alice);

        cheats.expectRevert("AFTER_WITHDRAW_ACCOUNT_IS_NOT_SAFE");
        usdoBank.withdraw(address(mockToken2), 1e8, alice, false);
        uint256 maxWithdrawBTC = usdoBank.getMaxWithdrawAmount(address(mockToken2), alice);
        assertEq(maxWithdrawBTC, 78571428);
        vm.stopPrank();
    }

    /// relist and then list
    function testClearAndRegister() public {
        mockToken1.transfer(alice, 10e18);

        vm.startPrank(address(usdoBank));
        usdo.transfer(alice, 1000e6);
        vm.stopPrank();

        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        vm.warp(1000);
        usdoBank.deposit(alice, address(mockToken1), 10e18, alice);
        vm.warp(2000);
        usdoBank.borrow(3000e6, alice, false);
        vm.stopPrank();
        vm.warp(3000);
        usdoBank.delistReserve(address(mockToken1));

        vm.warp(4000);
        usdoBank.relistReserve(address(mockToken1));

        vm.startPrank(alice);
        usdoBank.withdraw(address(mockToken1), 1e18, alice, false);
        vm.stopPrank();
        assertEq(usdoBank.getDepositBalance(address(mockToken1), alice), 9e18);
    }
}
