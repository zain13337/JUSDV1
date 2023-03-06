// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./USDOBankInit.t.sol";
//import "../../src/subaccount/SubaccountFactory.sol";
//import "../../src/subaccount/Subaccount.sol";

contract USDOBankMulticallTest is USDOBankInitTest {
    function testHelperDeposit() public {
        bytes memory a = usdoBank.getDepositData(alice, address(mockToken2), 10e18, alice);

        emit log_bytes(a);
    }

    function testHelperBorrow() public {
        bytes memory a = usdoBank.getBorrowData(10e18, address(0x123), false);
        emit log_bytes(a);
    }

    function testHelperRepay() public {
        bytes memory a = usdoBank.getRepayData(10e18, alice);
        emit log_bytes(a);
    }

    function testHelperWithdraw() public {
        bytes memory a = usdoBank.getWithdrawData(address(mockToken2), 10e18, alice, false);
        emit log_bytes(a);
    }

    function testHelperMultical() public {
        bytes[] memory data = new bytes[](2);
        data[0] = usdoBank.getDepositData(alice, address(mockToken1), 10e18, alice);
        data[1] = usdoBank.getBorrowData(3000e18, alice, false);
        bytes memory a = usdoBank.getMulticallData(data);
        emit log_bytes(a);
    }

    //    function testSubaccountMulticall() public {
    //        SubaccountFactory subaccountFactory = new SubaccountFactory();
    //        mockToken1.transfer(alice, 10e18);
    //        vm.startPrank(alice);
    //        address newSubaccount = subaccountFactory.newSubaccount();
    //        usdoBank.setOperator(newSubaccount, true);
    //        mockToken1.approve(address(usdoBank), 10e18);
    //        bytes[] memory data = new bytes[](2);
    //        data[0] = usdoBank.getDepositData(alice,address(mockToken1), 10e18, newSubaccount);
    //        data[1] = usdoBank.getBorrowData(3000e18, newSubaccount, false, newSubaccount);
    //        bytes memory dataAll = usdoBank.getMulticallData(data);
    //        Subaccount(newSubaccount).execute(address(usdoBank),dataAll,0);
    //        assertEq(usdoBank.getBorrowBalance(newSubaccount), 3000e18);
    //        assertEq(usdoBank.getDepositBalance(address(mockToken1), newSubaccount), 10e18);
    //        vm.stopPrank();
    //    }

    function testMulticall() public {
        mockToken1.transfer(alice, 10e18);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        bytes[] memory data = new bytes[](2);
        data[0] = usdoBank.getDepositData(alice, address(mockToken1), 10e18, alice);
        data[1] = usdoBank.getBorrowData(3000e6, alice, false);
        usdoBank.multiCall(data);
        assertEq(usdoBank.getDepositBalance(address(mockToken1), alice), 10e18);
        assertEq(usdoBank.getBorrowBalance(alice), 3000e6);
        //        delegateCall failed
        data[1] = "0";
        cheats.expectRevert("ERC20: insufficient allowance");
        usdoBank.multiCall(data);
    }
}
