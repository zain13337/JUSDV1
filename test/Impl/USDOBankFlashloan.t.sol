/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1*/
pragma solidity 0.8.9;

import "./USDOBankInit.t.sol";
import "../../src/Impl/FlashLoanRepay.sol";
import "../../src/Impl/USDOExchange.sol";
import "../mocks/MockFlashloan.sol";
import "../../src/support/SupportsDODO.sol";
import "../mocks/MockFlashloan2.sol";
import "../mocks/MockFlashloan3.sol";

contract USDOBankFlashloanTest is USDOBankInitTest {
    function testFlashloanWithdrawAmountIsTooBig() public {
        MockFlashloan mockFlashloan = new MockFlashloan();
        mockToken1.transfer(alice, 5e18);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 5e18);
        usdoBank.deposit(alice, address(mockToken1), 5e18, alice);
        bytes memory test = "just a test";
        cheats.expectRevert("WITHDRAW_AMOUNT_IS_TOO_BIG");
        usdoBank.flashLoan(
            address(mockFlashloan),
            address(mockToken1),
            6e18,
            alice,
            test
        );
        vm.stopPrank();
    }

    function testFlashloanWithdrawAmountIsZero() public {
        MockFlashloan mockFlashloan = new MockFlashloan();
        mockToken1.transfer(alice, 5e18);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 5e18);
        usdoBank.deposit(alice, address(mockToken1), 5e18, alice);
        bytes memory test = "just a test";
        cheats.expectRevert("WITHDRAW_AMOUNT_IS_ZERO");
        usdoBank.flashLoan(
            address(mockFlashloan),
            address(mockToken1),
            0,
            alice,
            test
        );
        vm.stopPrank();
    }

    function testFlashloanSuccess() public {
        MockFlashloan mockFlashloan = new MockFlashloan();
        mockToken1.transfer(alice, 5e18);

        mockToken2.transfer(address(mockFlashloan), 10e8);
        vm.startPrank(address(mockFlashloan));
        mockToken2.approve(address(usdoBank), 10e8);
        vm.stopPrank();

        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 5e18);
        usdoBank.deposit(alice, address(mockToken1), 5e18, alice);
        bytes memory test = "just a test";
        usdoBank.flashLoan(
            address(mockFlashloan),
            address(mockToken1),
            4e18,
            alice,
            test
        );
        vm.stopPrank();
        assertEq(usdoBank.getDepositBalance(address(mockToken1), alice), 1e18);
        assertEq(usdoBank.getDepositBalance(address(mockToken2), alice), 5e8);
        assertEq(mockToken2.balanceOf(address(mockFlashloan)), 5e8);
        assertEq(mockToken1.balanceOf(bob), 4e18);
    }

    function testFlashloan2() public {
        MockFlashloan2 mockFlashloan2 = new MockFlashloan2();
        mockToken1.transfer(alice, 5e18);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 5e18);
        usdoBank.deposit(alice, address(mockToken1), 5e18, alice);
        usdoBank.borrow(2000e6, alice, false);
        bytes memory test = "just a test";
        cheats.expectRevert("AFTER_FLASHLOAN_ACCOUNT_IS_NOT_SAFE");
        usdoBank.flashLoan(
            address(mockFlashloan2),
            address(mockToken1),
            5e18,
            alice,
            test
        );
        vm.stopPrank();
    }

    function testFlashloan3() public {
        MockFlashloan3 mockFlashloan3 = new MockFlashloan3();
        mockToken1.transfer(alice, 5e18);

        mockToken2.transfer(address(mockFlashloan3), 10e8);
        vm.startPrank(address(mockFlashloan3));
        mockToken2.approve(address(usdoBank), 10e8);
        vm.stopPrank();

        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 5e18);
        usdoBank.deposit(alice, address(mockToken1), 5e18, alice);
        bytes memory test = "just a test";

        cheats.expectRevert("ReentrancyGuard: flashLoan reentrant call");
        usdoBank.flashLoan(
            address(mockFlashloan3),
            address(mockToken1),
            1e18,
            alice,
            test
        );
        vm.stopPrank();
    }

    function testFlashloanRepayFK() public {
        MockERC20 usdc = new MockERC20(4000e18);
        SupportsDODO dodo = new SupportsDODO(
            address(usdc),
            address(mockToken1),
            address(jojoOracle1)
        );
        IERC20(usdc).transfer(address(dodo), 4000e18);

        USDOExchange usdoExchange = new USDOExchange(
            address(usdc),
            address(usdo)
        );
        usdo.mint(5000e18);
        IERC20(usdo).transfer(address(usdoExchange), 5000e18);
        FlashLoanRepay flashloanRepay = new FlashLoanRepay(
            address(usdoBank),
            address(usdoExchange),
            address(usdc),
            address(usdo)
        );

        mockToken1.transfer(alice, 1e18);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 1e18);
        usdoBank.deposit(alice, address(mockToken1), 1e18, alice);
        usdoBank.borrow(300e6, alice, false);
        bytes memory data = dodo.getSwapData(1e18, address(mockToken1));
        bytes memory param = abi.encode(dodo, dodo, data);
        usdoBank.flashLoan(
            address(flashloanRepay),
            address(mockToken1),
            1e18,
            alice,
            param
        );

        assertEq(IERC20(usdc).balanceOf(alice), 700e6);
        assertEq(usdoBank.getBorrowBalance(alice), 0);
        assertEq(IERC20(mockToken1).balanceOf(alice), 0);
        assertEq(IERC20(mockToken1).balanceOf(address(dodo)), 1e18);
        vm.stopPrank();
    }

    function testFlashloanRepayExchangeIsClose() public {
        MockERC20 usdc = new MockERC20(4000e18);
        SupportsDODO dodo = new SupportsDODO(
            address(usdc),
            address(mockToken1),
            address(jojoOracle1)
        );
        IERC20(usdc).transfer(address(dodo), 4000e18);

        USDOExchange usdoExchange = new USDOExchange(
            address(usdc),
            address(usdo)
        );
        usdo.mint(5000e18);
        IERC20(usdo).transfer(address(usdoExchange), 5000e18);
        FlashLoanRepay flashloanRepay = new FlashLoanRepay(
            address(usdoBank),
            address(usdoExchange),
            address(usdc),
            address(usdo)
        );
        usdoExchange.closeExchange();
        mockToken1.transfer(alice, 1e18);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 1e18);
        usdoBank.deposit(alice, address(mockToken1), 1e18, alice);
        usdoBank.borrow(300e6, alice, false);
        bytes memory data = dodo.getSwapData(1e16, address(mockToken1));
        bytes memory param = abi.encode(dodo, dodo, data);
        cheats.expectRevert("NOT_ALLOWED_TO_EXCHANGE");
        usdoBank.flashLoan(
            address(flashloanRepay),
            address(mockToken1),
            1e16,
            alice,
            param
        );
        vm.stopPrank();
    }

    function testFlashloanRepayAmountLessBorrowBalance() public {
        MockERC20 usdc = new MockERC20(4000e18);
        SupportsDODO dodo = new SupportsDODO(
            address(usdc),
            address(mockToken1),
            address(jojoOracle1)
        );
        IERC20(usdc).transfer(address(dodo), 4000e18);
        USDOExchange usdoExchange = new USDOExchange(
            address(usdc),
            address(usdo)
        );
        usdo.mint(5000e18);
        IERC20(usdo).transfer(address(usdoExchange), 5000e18);
        FlashLoanRepay flashloanRepay = new FlashLoanRepay(
            address(usdoBank),
            address(usdoExchange),
            address(usdc),
            address(usdo)
        );
        mockToken1.transfer(alice, 1e18);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 1e18);
        usdoBank.deposit(alice, address(mockToken1), 1e18, alice);
        usdoBank.borrow(300e6, alice, false);
        bytes memory data = dodo.getSwapData(1e15, address(mockToken1));
        bytes memory param = abi.encode(dodo, dodo, data);
        usdoBank.flashLoan(
            address(flashloanRepay),
            address(mockToken1),
            1e15,
            alice,
            param
        );
        assertEq(usdoBank.getBorrowBalance(alice), 299e6);
        vm.stopPrank();
    }

    function testFlashloanRepayRevert() public {
        MockERC20 usdc = new MockERC20(4000e18);
        SupportsDODO dodo = new SupportsDODO(
            address(usdc),
            address(mockToken1),
            address(jojoOracle1)
        );
        IERC20(usdc).transfer(address(dodo), 2e6);
        USDOExchange usdoExchange = new USDOExchange(
            address(usdc),
            address(usdo)
        );
        usdo.mint(5000e18);
        IERC20(usdo).transfer(address(usdoExchange), 5000e18);
        FlashLoanRepay flashloanRepay = new FlashLoanRepay(
            address(usdoBank),
            address(usdoExchange),
            address(usdc),
            address(usdo)
        );
        mockToken1.transfer(alice, 3e18);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 3e18);
        usdoBank.deposit(alice, address(mockToken1), 3e18, alice);
        usdoBank.borrow(300e6, alice, false);
        bytes memory data = dodo.getSwapData(3e18, address(mockToken1));
        bytes memory param = abi.encode(dodo, dodo, data);
        cheats.expectRevert("ERC20: transfer amount exceeds balance");
        usdoBank.flashLoan(
            address(flashloanRepay),
            address(mockToken1),
            3e18,
            alice,
            param
        );
        vm.stopPrank();
    }
}
