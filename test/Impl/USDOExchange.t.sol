/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0*/
pragma solidity ^0.8.9;

import "forge-std/Test.sol";

import "../mocks/MockERC20.sol";
import "../../src/token/USDO.sol";
import "../../src/Impl/USDOExchange.sol";
import "../mocks/MockJOJODealer.sol";

interface Cheats {
    function expectRevert() external;
    function expectRevert(bytes calldata) external;
}

contract USDOExchangeTest is Test {
    Cheats internal constant cheats = Cheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    USDO public usdo;
    MockERC20 public usdc;
    address internal alice = address(1);
    address internal bob = address(2);
    address internal jim = address(4);
    address internal owner = address(3);
    USDOExchange usdoExchange;

    MockJOJODealer public jojoDealer;

    function setUp() public {
        usdo = new USDO(6);
        usdc = new MockERC20(2000e18);
        usdoExchange = new USDOExchange(address(usdc), address(usdo));
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(jim, "Jim");
        vm.label(owner, "Owner");

        usdc.transfer(alice, 2000e18);
        usdo.mint(10000e18);
        usdo.transfer(address(usdoExchange), 10000e18);
    }

    function testExchangeSuccess() public {
        vm.startPrank(alice);
        usdc.approve(address(usdoExchange), 1000e18);
        usdoExchange.buyUSDO(1000e18, alice);
        assertEq(usdo.balanceOf(alice), 1000e18);
        assertEq(usdc.balanceOf(alice), 1000e18);
    }

    function testExchangeSuccessClose() public {
        usdoExchange.closeExchange();
        vm.startPrank(alice);
        usdc.approve(address(usdoExchange), 1000e18);
        cheats.expectRevert("NOT_ALLOWED_TO_EXCHANGE");
        usdoExchange.buyUSDO(1000e18, alice);
        vm.stopPrank();
        usdoExchange.openExchange();
        vm.startPrank(alice);
        usdc.approve(address(usdoExchange), 1000e18);
        usdoExchange.buyUSDO(1000e18, alice);
    }
}
