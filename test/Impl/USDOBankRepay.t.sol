// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "./USDOBankInit.t.sol";

contract USDOBankRepayTest is USDOBankInitTest {
    function testRepayUSDOSuccess() public {
        mockToken1.transfer(alice, 100e18);

        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        usdoBank.deposit(alice, address(mockToken1), 10e18, alice);
        usdoBank.borrow(5000e6, alice, false);
        usdo.approve(address(usdoBank), 5000e6);
        usdoBank.repay(5000e6, alice);

        uint256 adjustAmount = usdoBank.getBorrowBalance(alice);
        assertEq(adjustAmount, 0);
        assertEq(usdo.balanceOf(alice), 0);
        assertEq(mockToken1.balanceOf(alice), 90e18);
        assertEq(usdoBank.getDepositBalance(address(mockToken1), alice), 10e18);
        vm.stopPrank();
    }

    function testRepayUSDOtRateSuccess() public {
        mockToken1.transfer(alice, 100e18);
        mockToken2.transfer(alice, 100e8);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        mockToken2.approve(address(usdoBank), 10e8);
        usdoBank.deposit(alice, address(mockToken1), 10e18, alice);
        vm.warp(1000);
        usdoBank.deposit(alice, address(mockToken2), 10e8, alice);
        vm.warp(2000);
        // max borrow amount
        uint256 rateT2 = usdoBank.t0Rate()
            + (usdoBank.borrowFeeRate() * ((block.timestamp - usdoBank.lastUpdateTimestamp()))) / 365 days;
        usdoBank.borrow(3000e6, alice, false);
        usdo.approve(address(usdoBank), 6000e6);
        vm.warp(3000);
        uint256 rateT3 = usdoBank.t0Rate()
            + (usdoBank.borrowFeeRate() * ((block.timestamp - usdoBank.lastUpdateTimestamp()))) / 365 days;
        usdo.approve(address(usdoBank), 3000e6);
        usdoBank.repay(1500e6, alice);
        usdoBank.borrow(1000e6, alice, false);
        uint256 aliceBorrowed = usdoBank.getBorrowBalance(alice);
        emit log_uint((3000e6 * 1e18) / rateT2 + 1 - (1500e6 * 1e18) / rateT3 + (1000e6 * 1e18) / rateT3 + 1);
        console.log((2499997149 * rateT3) / 1e18);
        vm.stopPrank();
        assertEq(aliceBorrowed, 2500001903);
    }

    function testRepayTotalUSDOtRateSuccess() public {
        mockToken1.transfer(alice, 100e18);
        vm.startPrank(address(usdoBank));
        usdo.transfer(alice, 1000e6);
        vm.stopPrank();
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        usdoBank.deposit(alice, address(mockToken1), 10e18, alice);
        vm.warp(1000);
        usdoBank.borrow(5000e6, alice, false);
        uint256 rateT1 = usdoBank.getTRate();
        uint256 usedBorrowed = (5000e6 * 1e18) / rateT1;
        usdo.approve(address(usdoBank), 6000e6);
        vm.warp(2000);
        usdoBank.repay(6000e6, alice);
        uint256 aliceBorrowed = usdoBank.getBorrowBalance(alice);
        uint256 rateT2 = usdoBank.getTRate();
        emit log_uint(6000e6 - ((usedBorrowed * rateT2) / 1e18 + 1));
        assertEq(usdo.balanceOf(alice), 999996829);
        assertEq(0, aliceBorrowed);
        vm.stopPrank();
    }

    function testRepayAmountisZero() public {
        mockToken1.transfer(alice, 100e18);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        usdoBank.deposit(alice, address(mockToken1), 10e18, alice);
        usdoBank.borrow(5000e6, alice, false);
        cheats.expectRevert("REPAY_AMOUNT_IS_ZERO");
        usdoBank.repay(0, alice);
        vm.stopPrank();
    }

    // eg: emit log_uint((3000e18 * 1e18/ rateT2) * rateT2 / 1e18)
    function testRepayUSDOInSameTimestampSuccess() public {
        mockToken1.transfer(alice, 100e18);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        usdoBank.deposit(alice, address(mockToken1), 10e18, alice);
        vm.warp(2000);
        uint256 rateT2 = usdoBank.t0Rate()
            + (usdoBank.borrowFeeRate() * ((block.timestamp - usdoBank.lastUpdateTimestamp()))) / 365 days;
        usdoBank.borrow(3000e6, alice, false);
        uint256 aliceUsedBorrowed = usdoBank.getBorrowBalance(alice);
        emit log_uint((3000e6 * 1e18) / rateT2);
        usdo.approve(address(usdoBank), 3000e6);
        usdoBank.repay(3000e6, alice);
        uint256 aliceBorrowed = usdoBank.getBorrowBalance(alice);
        assertEq(aliceUsedBorrowed, 3000e6);
        assertEq(aliceBorrowed, 0);
        vm.stopPrank();
    }

    function testRepayInSameTimestampSuccess() public {
        mockToken1.transfer(alice, 100e18);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        usdoBank.deposit(alice, address(mockToken1), 10e18, alice);
        vm.warp(2000);
        uint256 rateT2 = usdoBank.getTRate();
        usdoBank.borrow(3000e6, alice, false);
        uint256 aliceUsedBorrowed = usdoBank.getBorrowBalance(alice);
        assertEq(aliceUsedBorrowed, 3000e6);
        vm.warp(2001);
        uint256 rateT3 = usdoBank.getTRate();
        usdo.approve(address(usdoBank), 3000e6);
        usdoBank.repay(3000e6, alice);
        uint256 aliceBorrowed = usdoBank.getBorrowBalance(alice);
        emit log_uint((3000e6 * 1e18) / rateT2 + 1 - (3000e6 * 1e18) / rateT3);

        assertEq(aliceBorrowed, (3 * rateT3) / 1e18);
        vm.stopPrank();
    }

    function testRepayByGeneralRepay() public {
        mockToken1.transfer(alice, 10e18);
        address[] memory userLiset = new address[](1);
        userLiset[0] = address(alice);
        uint256[] memory amountList = new uint256[](1);
        amountList[0] = 1000e6;
        USDC.mint(userLiset, amountList);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        usdoBank.deposit(alice, address(mockToken1), 10e18, alice);
        usdoBank.borrow(3000e6, alice, false);

        IERC20(USDC).approve(address(generalRepay), 1000e6);
        bytes memory test;
        generalRepay.repayUSDO(address(USDC), 1000e6, alice, test);
        assertEq(usdoBank.getBorrowBalance(alice), 2000e6);
    }

    function testRepayCollateralWallet() public {
        mockToken1.transfer(alice, 15e18);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        usdoBank.deposit(alice, address(mockToken1), 10e18, alice);
        usdoBank.borrow(3000e6, alice, false);

        mockToken1.approve(address(generalRepay), 1e18);

        bytes memory data = dodo.getSwapData(1e18, address(mockToken1));
        bytes memory param = abi.encode(dodo, dodo, data);
        generalRepay.repayUSDO(address(mockToken1), 1e18, alice, param);
        assertEq(usdoBank.getBorrowBalance(alice), 2000e6);
        assertEq(mockToken1.balanceOf(alice), 4e18);
    }
    // Fuzzy test
    // function testRepayFuzzyAmount(uint256 amount) public {
    //     mockToken1.transfer(alice, 100e18);
    //     usdo.transfer(alice, amount);
    //     vm.startPrank(alice);
    //     mockToken1.approve(address(usdoBank), 10e18);
    //     usdoBank.deposit(address(mockToken1), 10e18, alice);
    //     usdoBank.borrow(5000e18, alice, false, alice);
    //     usdo.approve(address(usdoBank), amount);
    //     usdoBank.repay(amount, alice);
    //     vm.stopPrank();
    // }

    // function testRepayFuzzyTo(address to) public {
    //     mockToken1.transfer(alice, 100e18);
    //     vm.startPrank(alice);
    //     mockToken1.approve(address(usdoBank), 10e18);
    //     usdoBank.deposit(address(mockToken1), 10e18, alice);
    //     usdoBank.borrow(5000e18, alice, false, alice);
    //     usdo.approve(address(usdoBank), 5000e6);
    //     usdoBank.repay(5000e18, to);
    //     vm.stopPrank();
    // }
}
