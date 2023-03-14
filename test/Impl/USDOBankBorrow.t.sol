// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "./USDOBankInit.t.sol";
import "../mocks/MockJOJODealerRevert.sol";

contract USDOBankBorrowTest is USDOBankInitTest {
    MockJOJODealerRevert public jojoDealerRevert = new MockJOJODealerRevert();

    // no tRate just one token
    function testBorrowUSDOSuccess() public {
        mockToken1.transfer(alice, 100e18);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        usdoBank.deposit(alice, address(mockToken1), 10e18, alice);
        usdoBank.borrow(5000e6, alice, false);
        uint256 usdoBalance = usdoBank.getBorrowBalance(alice);
        assertEq(usdoBalance, 5000e6);
        assertEq(usdo.balanceOf(alice), 5000e6);
        assertEq(mockToken1.balanceOf(alice), 90e18);
        assertEq(usdoBank.getDepositBalance(address(mockToken1), alice), 10e18);
        vm.stopPrank();
    }

    // no tRate two token
    function testBorrow2CollateralUSDOSuccess() public {
        mockToken1.transfer(alice, 100e18);
        mockToken2.transfer(alice, 100e8);

        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        mockToken2.approve(address(usdoBank), 10e8);
        usdoBank.deposit(alice, address(mockToken1), 10e18, alice);
        usdoBank.deposit(alice, address(mockToken2), 10e8, alice);
        usdoBank.borrow(6000e6, alice, false);
        uint256 usdoBalance = usdoBank.getBorrowBalance(alice);

        assertEq(usdoBalance, 6000e6);
        assertEq(usdo.balanceOf(alice), 6000e6);
        assertEq(mockToken1.balanceOf(alice), 90e18);
        assertEq(usdoBank.getDepositBalance(address(mockToken1), alice), 10e18);
        assertEq(usdoBank.getDepositBalance(address(mockToken2), alice), 10e8);
        vm.stopPrank();
    }

    // have tRate, one token
    function testBorrowUSDOtRateSuccess() public {
        mockToken1.transfer(alice, 100e18);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        usdoBank.deposit(alice, address(mockToken1), 10e18, alice);

        vm.warp(1000);
        usdoBank.borrow(5000e6, alice, false);
        uint256 usdoBalance = usdoBank.getBorrowBalance(alice);
        assertEq(usdoBalance, 5000e6);
        assertEq(usdo.balanceOf(alice), 5000e6);
        assertEq(mockToken1.balanceOf(alice), 90e18);
        assertEq(usdoBank.getDepositBalance(address(mockToken1), alice), 10e18);

        vm.stopPrank();
    }

    //  > max mint amount
    function testBorrowUSDOFailMaxMintAmount() public {
        mockToken1.transfer(alice, 100e18);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        usdoBank.deposit(alice, address(mockToken1), 10e18, alice);

        cheats.expectRevert("AFTER_BORROW_ACCOUNT_IS_NOT_SAFE");
        usdoBank.borrow(8001e6, alice, false);
        vm.stopPrank();
    }

    function testBorrowUSDOFailPerAccount() public {
        mockToken1.transfer(alice, 100e18);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        usdoBank.deposit(alice, address(mockToken1), 10e18, alice);
        cheats.expectRevert("EXCEED_THE_MAX_BORROW_AMOUNT_PER_ACCOUNT");
        usdoBank.borrow(7000e18, alice, false);
        vm.stopPrank();
    }

    function testBorrowUSDOFailTotalAmount() public {
        mockToken1.transfer(alice, 200e18);
        mockToken1.transfer(bob, 200e18);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 200e18);
        usdoBank.deposit(alice, address(mockToken1), 200e18, alice);
        usdoBank.borrow(100000e6, alice, false);
        vm.stopPrank();

        vm.startPrank(bob);
        mockToken1.approve(address(usdoBank), 10e18);
        usdoBank.deposit(bob, address(mockToken1), 10e18, bob);
        cheats.expectRevert("EXCEED_THE_MAX_BORROW_AMOUNT_TOTAL");
        usdoBank.borrow(5000e6, bob, false);

        vm.stopPrank();
    }

    function testBorrowDepositToJOJO() public {
        mockToken1.transfer(alice, 100e18);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        usdoBank.deposit(alice, address(mockToken1), 10e18, alice);
        usdoBank.borrow(5000e6, alice, true);
        vm.stopPrank();
    }

    // https://github.com/foundry-rs/foundry/issues/3497 for revert test

    function testBorrowDepositToJOJORevert() public {
        mockToken1.transfer(alice, 100e18);
        usdoBank.updateJOJODealer(address(jojoDealerRevert));
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        usdoBank.deposit(alice, address(mockToken1), 10e18, alice);
        cheats.expectRevert("test For revert");
        usdoBank.borrow(5000e6, alice, true);
        vm.stopPrank();
    }

    function testDepositTooMany() public {
        usdoBank.updateReserveParam(address(mockToken1), 8e17, 2300e18, 230e18, 100000e18);
        usdoBank.updateMaxBorrowAmount(200000e18, 300000e18);
        mockToken1.transfer(alice, 200e18);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 200e18);
        usdoBank.deposit(alice, address(mockToken1), 200e18, alice);
        cheats.expectRevert("AFTER_BORROW_ACCOUNT_IS_NOT_SAFE");
        usdoBank.borrow(200000e6, alice, false);
        vm.stopPrank();
    }

    function testGetDepositMaxData() public {
        usdoBank.updateReserveParam(address(mockToken1), 8e17, 2300e18, 230e18, 100000e18);
        usdoBank.updateReserveParam(address(mockToken2), 8e17, 2300e18, 230e18, 100000e18);
        usdoBank.updateMaxBorrowAmount(200000e18, 300000e18);
        mockToken1.transfer(alice, 10e18);
        mockToken2.transfer(alice, 1e18);

        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        mockToken2.approve(address(usdoBank), 1e18);
        usdoBank.deposit(alice, address(mockToken1), 10e18, alice);
        usdoBank.deposit(alice, address(mockToken2), 1e18, alice);
        usdoBank.borrow(8000e6, alice, false);

        uint256 maxMint = usdoBank.getDepositMaxMintAmount(alice);
        console.log("max mint", maxMint);
    }

    // Fuzzy test

    // function testBorrowFuzzyAmount(uint256 amount) public {
    //     mockToken1.transfer(alice, 100e18);
    //     vm.startPrank(alice);
    //     mockToken1.approve(address(usdoBank), 100e18);
    //     usdoBank.deposit(address(mockToken1), 100e18, alice);
    //     usdoBank.borrow(amount, alice, false, alice);
    // }

    // function testBorrowFuzzyTo(address to) public {
    //     mockToken1.transfer(alice, 100e18);
    //     vm.startPrank(alice);
    //     mockToken1.approve(address(usdoBank), 10e18);
    //     usdoBank.deposit(address(mockToken1), 10e18, alice);
    //     usdoBank.borrow(5000e18, to, false, alice);
    //     assertEq(usdo.balanceOf(to), 5000e18);
    // }

    // function testBorrowFuzzyFrom(address from) public {
    //     mockToken1.transfer(alice, 100e18);
    //     vm.startPrank(alice);
    //     usdoBank.borrow(5000e18, alice, false, from);
    // }
}
