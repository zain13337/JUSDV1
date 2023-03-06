// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./USDOBankInit.t.sol";
import "../mocks/MockToken.sol";

contract USDOBankTest is USDOBankInitTest {
    function testDepositSuccess() public {
        mockToken1.transfer(alice, 10e18);
        mockToken2.transfer(alice, 10e18);
        // change msg.sender
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 5e18);
        usdoBank.deposit(alice, address(mockToken1), 5e18, alice);
        uint256 balance = usdoBank.getDepositBalance(address(mockToken1), alice);
        assertEq(balance, 5e18);
        assertEq(usdoBank.getBorrowBalance(msg.sender), 0);
        address[] memory userList = usdoBank.getUserCollateralList(alice);
        assertEq(userList[0], address(mockToken1));
        vm.stopPrank();
    }

    function testAll() public {
        mockToken1.transfer(alice, 10e18);
        // change msg.sender
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        usdoBank.deposit(alice, address(mockToken1), 5e18, alice);
        usdoBank.deposit(alice, address(mockToken1), 5e18, alice);
        usdoBank.borrow(1000e6, alice, false);
        usdoBank.borrow(1000e6, alice, false);
        usdo.approve(address(usdoBank), 2000e18);
        usdoBank.repay(1000e6, alice);
        usdoBank.repay(1000e6, alice);
        usdoBank.withdraw(address(mockToken1), 5e18, alice, false);
        usdoBank.withdraw(address(mockToken1), 5e18, alice, false);
        vm.stopPrank();
    }

    function testDepositToBobSuccess() public {
        mockToken1.transfer(alice, 10e18);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 5);
        usdoBank.deposit(alice, address(mockToken1), 5, bob);
        uint256 balance = usdoBank.getDepositBalance(address(mockToken1), alice);

        assertEq(balance, 0);
        assertEq(usdoBank.getDepositBalance(address(mockToken1), bob), 5);
        vm.stopPrank();
    }

    function testDepositAmountIs0Fail() public {
        mockToken1.transfer(alice, 10e18);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 5);
        cheats.expectRevert("DEPOSIT_AMOUNT_IS_ZERO");
        usdoBank.deposit(alice, address(mockToken1), 0, alice);
        vm.stopPrank();
    }

    function testDepositFailAmountMoreThanPerAccount() public {
        mockToken1.transfer(alice, 2031e18);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 2031e18);
        cheats.expectRevert("EXCEED_THE_MAX_DEPOSIT_AMOUNT_PER_ACCOUNT");
        usdoBank.deposit(alice, address(mockToken1), 2031e18, alice);
        vm.stopPrank();
    }

    function testDepositFailAmountMoreTotal() public {
        mockToken1.transfer(alice, 2030e18);
        mockToken1.transfer(bob, 2030e18);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 2030e18);
        usdoBank.deposit(alice, address(mockToken1), 2030e18, alice);
        vm.stopPrank();
        assertEq(usdoBank.getDepositBalance(address(mockToken1), alice), 2030e18);

        vm.startPrank(bob);
        mockToken1.approve(address(usdoBank), 2030e18);
        cheats.expectRevert("EXCEED_THE_MAX_DEPOSIT_AMOUNT_TOTAL");
        usdoBank.deposit(bob, address(mockToken1), 2030e18, bob);
        vm.stopPrank();
    }

    function testDepositTokenNotInReserve() public {
        MockToken mk = new MockToken(100e18);
        mk.transfer(alice, 10e18);

        vm.startPrank(alice);
        mk.approve(address(usdoBank), 10e18);

        cheats.expectRevert("RESERVE_NOT_ALLOW_DEPOSIT");
        usdoBank.deposit(alice, address(mk), 10e18, alice);
        vm.stopPrank();
    }
    // Fuzzy test

    // function testDepositFuzzy(address to) public {
    //     mockToken1.transfer(alice, 10e18);
    //     vm.startPrank(alice);
    //     mockToken1.approve(address(usdoBank), 10e18);
    //     usdoBank.deposit(address(mockToken1), 10e18, to);
    //     uint256 balance = usdoBank.getDepositBalance(address(mockToken1), to);
    //     assertEq(usdoBank.getDepositBalanceTotal(address(mockToken1)), 10e18);
    //     assertEq(balance, 10e18);
    // }

    // function testDepositFuzzyCollateral(address collateral) public {
    //     vm.startPrank(alice);
    //     usdoBank.deposit(address(collateral), 10e18, alice);
    // }
}
