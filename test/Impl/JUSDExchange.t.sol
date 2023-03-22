/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1*/
pragma solidity ^0.8.9;

import "forge-std/Test.sol";

import "../mocks/MockERC20.sol";
import "../../src/token/JUSD.sol";
import "../../src/Impl/JUSDExchange.sol";
import "../mocks/MockJOJODealer.sol";

interface Cheats {
    function expectRevert() external;

    function expectRevert(bytes calldata) external;
}

contract JUSDExchangeTest is Test {
    Cheats internal constant cheats =
        Cheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    JUSD public usdo;
    MockERC20 public usdc;
    address internal alice = address(1);
    address internal bob = address(2);
    address internal jim = address(4);
    address internal owner = address(3);
    JUSDExchange usdoExchange;

    MockJOJODealer public jojoDealer;

    function setUp() public {
        usdo = new JUSD(6);
        usdc = new MockERC20(2000e6);
        usdoExchange = new JUSDExchange(address(usdc), address(usdo));
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(jim, "Jim");
        vm.label(owner, "Owner");

        usdc.transfer(alice, 2000e6);
        usdo.mint(10000e6);
        usdo.transfer(address(usdoExchange), 10000e6);
    }

    function testExchangeSuccess() public {
        vm.startPrank(alice);
        usdc.approve(address(usdoExchange), 1000e6);
        usdoExchange.buyJUSD(1000e6, alice);
        assertEq(usdo.balanceOf(alice), 1000e6);
        assertEq(usdc.balanceOf(alice), 1000e6);
    }

    function testExchangeSuccessClose() public {
        usdoExchange.closeExchange();
        vm.startPrank(alice);
        usdc.approve(address(usdoExchange), 1000e6);
        cheats.expectRevert("NOT_ALLOWED_TO_EXCHANGE");
        usdoExchange.buyJUSD(1000e6, alice);
        vm.stopPrank();
        usdoExchange.openExchange();
        vm.startPrank(alice);
        usdc.approve(address(usdoExchange), 1000e6);
        usdoExchange.buyJUSD(1000e6, alice);
    }
}
