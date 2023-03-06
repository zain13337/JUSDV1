// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./USDOBankInit.t.sol";
import "../../src/Impl/FlashLoanLiquidate.sol";
import "../mocks/MockChainLink900.sol";

contract USDOBankLiquidateCollateralTest is USDOBankInitTest {
    /// @notice user just deposit not borrow, account is safe
    function testLiquidateCollateralAccountIsSafe() public {
        mockToken1.transfer(alice, 10e18);
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        usdoBank.deposit(alice, address(mockToken1), 10e18, alice);
        bool ifSafe = usdoBank.isAccountSafe(alice);
        assertEq(ifSafe, true);
        vm.stopPrank();
        vm.startPrank(bob);
        cheats.expectRevert("ACCOUNT_IS_SAFE");
        bytes memory afterParam = abi.encode(address(usdo), 10e18);
        usdoBank.liquidate(alice, address(mockToken1), bob, 10e18, afterParam, 0);
        vm.stopPrank();
    }

    function testLiquidateCollateralAmountIsZero() public {
        mockToken1.transfer(alice, 10e18);
        vm.startPrank(address(usdoBank));
        usdo.transfer(bob, 5000e18);
        vm.stopPrank();
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        usdoBank.deposit(alice, address(mockToken1), 10e18, alice);
        usdoBank.borrow(5000e6, alice, false);
        vm.stopPrank();
        vm.startPrank(address(this));
        MockChainLinkBadDebt mockChainLinkBadDebt = new MockChainLinkBadDebt();
        JOJOOracleAdaptor jojoOracle3 = new JOJOOracleAdaptor(
            address(mockChainLinkBadDebt),
            20,
            86400
        );
        usdoBank.updateOracle(address(mockToken1), address(jojoOracle3));
        vm.stopPrank();
        vm.startPrank(bob);
        usdo.approve(address(usdoBank), 5225e18);
        vm.warp(3000);
        cheats.expectRevert("LIQUIDATE_AMOUNT_IS_ZERO");
        bytes memory afterParam = abi.encode(address(usdo), 5000e6);
        usdoBank.liquidate(alice, address(mockToken1), bob, 0, afterParam, 0);
    }

    function testLiquidateCollateralPriceProtect() public {
        mockToken1.transfer(alice, 10e18);
        vm.startPrank(address(usdoBank));
        usdo.transfer(bob, 5000e18);
        vm.stopPrank();
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        usdoBank.deposit(alice, address(mockToken1), 10e18, alice);
        usdoBank.borrow(7426e6, alice, false);
        vm.stopPrank();
        vm.startPrank(address(this));
        MockChainLink900 eth900 = new MockChainLink900();
        JOJOOracleAdaptor jojoOracle900 = new JOJOOracleAdaptor(
            address(eth900),
            20,
            86400
        );
        usdoBank.updateOracle(address(mockToken1), address(jojoOracle900));
        dodo.addTokenPrice(address(mockToken1), address(jojoOracle900));
        vm.stopPrank();

        vm.startPrank(bob);
        usdo.approve(address(usdoBank), 5225e18);
        vm.warp(3000);
        bytes memory param = abi.encode(dodo, dodo, address(bob), bytes4(keccak256("swap(uint256,address)")));
        FlashLoanLiquidate flashloanRepay =
            new FlashLoanLiquidate(address(usdoBank), address(usdoExchange), address(USDC), address(usdo), insurance);
        bytes memory afterParam = abi.encode(address(flashloanRepay), param);
        cheats.expectRevert("LIQUIDATION_PRICE_PROTECTION");
        usdoBank.liquidate(alice, address(mockToken1), bob, 10e18, afterParam, 10e18);
    }

    function testSelfLiquidateCollateral() public {
        mockToken1.transfer(alice, 10e18);
        vm.startPrank(address(usdoBank));
        usdo.transfer(bob, 5000e18);
        vm.stopPrank();
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        usdoBank.deposit(alice, address(mockToken1), 10e18, alice);
        usdoBank.borrow(7426e6, alice, false);
        vm.stopPrank();
        vm.startPrank(address(this));
        MockChainLink900 eth900 = new MockChainLink900();
        JOJOOracleAdaptor jojoOracle900 = new JOJOOracleAdaptor(
            address(eth900),
            20,
            86400
        );
        usdoBank.updateOracle(address(mockToken1), address(jojoOracle900));
        dodo.addTokenPrice(address(mockToken1), address(jojoOracle900));
        vm.stopPrank();

        vm.startPrank(alice);
        vm.warp(3000);
        bytes memory param = abi.encode(dodo, dodo, address(bob), bytes4(keccak256("swap(uint256,address)")));
        FlashLoanLiquidate flashloanRepay =
            new FlashLoanLiquidate(address(usdoBank), address(usdoExchange), address(USDC), address(usdo), insurance);
        bytes memory afterParam = abi.encode(address(flashloanRepay), param);
        cheats.expectRevert("SELF_LIQUIDATION_NOT_ALLOWED");
        usdoBank.liquidate(alice, address(mockToken1), alice, 10e18, afterParam, 10e18);
    }

    function testLiquidateCollateralAmountIsTooBig() public {
        mockToken1.transfer(alice, 10e18);
        vm.startPrank(address(usdoBank));
        usdo.transfer(bob, 5000e18);
        vm.stopPrank();
        vm.startPrank(alice);
        mockToken1.approve(address(usdoBank), 10e18);
        usdoBank.deposit(alice, address(mockToken1), 10e18, alice);
        usdoBank.borrow(7426e6, alice, false);
        vm.stopPrank();
        vm.startPrank(address(this));
        MockChainLink900 eth900 = new MockChainLink900();
        JOJOOracleAdaptor jojoOracle900 = new JOJOOracleAdaptor(
            address(eth900),
            20,
            86400
        );
        usdoBank.updateOracle(address(mockToken1), address(jojoOracle900));
        dodo.addTokenPrice(address(mockToken1), address(jojoOracle900));
        vm.stopPrank();

        vm.startPrank(bob);
        usdo.approve(address(usdoBank), 5225e18);
        vm.warp(3000);
        bytes memory param = abi.encode(dodo, dodo, address(bob), bytes4(keccak256("swap(uint256,address)")));
        FlashLoanLiquidate flashloanRepay =
            new FlashLoanLiquidate(address(usdoBank), address(usdoExchange), address(USDC), address(usdo), insurance);
        bytes memory afterParam = abi.encode(address(flashloanRepay), param);
        cheats.expectRevert("LIQUIDATE_AMOUNT_IS_TOO_BIG");
        usdoBank.liquidate(alice, address(mockToken1), bob, 11e18, afterParam, 0);
    }

    // // Fuzzy test
    // //     function testLiquidateFuzzyLiquidatedTrader(address liquidatedTrader) public {
    // //         mockToken1.transfer(alice, 10e18);
    // //         vm.startPrank(alice);
    // //         mockToken1.approve(address(usdoBank), 10e18);
    // //         usdoBank.deposit(address(mockToken1), 10e18, alice);
    // //         usdoBank.liquidate(liquidatedTrader, address(mockToken1), 10e18, address(usdo), 10e18, alice);
    // //         vm.stopPrank();
    // //     }
    // //     function testLiquidateFuzzyLiquidationCollateral(address liquidationCollateral) public {
    // //         vm.startPrank(alice);
    // //         usdoBank.liquidate(alice, liquidationCollateral, 10e18, address(usdo), 5000e18, alice);
    // //     }

    // // //
    // //     function testLiquidateFuzzyLiquidationAmount(uint256 amount) public {
    // //         mockToken1.transfer(alice, 10e18);
    // //         vm.startPrank(address(usdoBank));
    // //         usdo.transfer(bob, 5000e18);
    // //         vm.stopPrank();
    // //         vm.startPrank(alice);
    // //         mockToken1.approve(address(usdoBank), 10e18);
    // //         usdoBank.deposit(address(mockToken1), 10e18, alice);
    // //         usdoBank.borrow(5000e18, alice, false, alice);
    // //         vm.stopPrank();
    // //         vm.startPrank(address(this));
    // //         MockChainLinkBadDebt mockChainLinkBadDebt = new MockChainLinkBadDebt();
    // //         JOJOOracleAdaptor jojoOracle3 = new JOJOOracleAdaptor(
    // //             address(mockChainLinkBadDebt),
    // //             20
    // //         );
    // //         usdoBank.updateOracle(address(mockToken1), address(jojoOracle3));
    // //         vm.stopPrank();

    // //         vm.startPrank(bob);
    // //         usdo.approve(address(usdoBank), 5225e18);
    // //         vm.warp(3000);
    // //         usdoBank.liquidate(alice, address(mockToken1), amount, address(usdo), 5000e18, bob);
    // //     }

    // //      function testLiquidateFuzzyDepositCollateral(address depositCollateral) public {
    // //         mockToken1.transfer(alice, 10e18);
    // //         vm.startPrank(address(usdoBank));
    // //         usdo.transfer(bob, 5000e18);
    // //         vm.stopPrank();
    // //         vm.startPrank(alice);
    // //         mockToken1.approve(address(usdoBank), 10e18);
    // //         usdoBank.deposit(address(mockToken1), 10e18, alice);
    // //         usdoBank.borrow(5000e18, alice, false, alice);
    // //         vm.stopPrank();
    // //         vm.startPrank(address(this));
    // //         MockChainLinkBadDebt mockChainLinkBadDebt = new MockChainLinkBadDebt();
    // //         JOJOOracleAdaptor jojoOracle3 = new JOJOOracleAdaptor(
    // //             address(mockChainLinkBadDebt),
    // //             20
    // //         );
    // //         usdoBank.updateOracle(address(mockToken1), address(jojoOracle3));
    // //         vm.stopPrank();

    // //         vm.startPrank(bob);
    // //         usdo.approve(address(usdoBank), 5225e18);
    // //         vm.warp(3000);
    // //         usdoBank.liquidate(alice, address(mockToken1), 10e18, depositCollateral, 5000e18, bob);
    // //     }

    // //      function testLiquidateFuzzyDepositAmount(uint256 depositAmount) public {
    // //         mockToken1.transfer(alice, 10e18);

    // //         vm.startPrank(address(usdoBank));
    // //         usdo.transfer(bob, depositAmount);
    // //         vm.stopPrank();

    // //         vm.startPrank(alice);
    // //         mockToken1.approve(address(usdoBank), 10e18);
    // //         usdoBank.deposit(address(mockToken1), 10e18, alice);
    // //         usdoBank.borrow(5000e18, alice, false, alice);
    // //         vm.stopPrank();

    // //         vm.startPrank(address(this));
    // //         MockChainLinkBadDebt mockChainLinkBadDebt = new MockChainLinkBadDebt();
    // //         JOJOOracleAdaptor jojoOracle3 = new JOJOOracleAdaptor(
    // //             address(mockChainLinkBadDebt),
    // //             20
    // //         );
    // //         usdoBank.updateOracle(address(mockToken1), address(jojoOracle3));
    // //         vm.stopPrank();

    // //         vm.startPrank(bob);
    // //         usdo.approve(address(usdoBank), depositAmount);
    // //         vm.warp(3000);
    // //         usdoBank.liquidate(alice, address(mockToken1), 10e18, address(usdo), depositAmount, bob);
    // //     }

    // //     function testLiquidateFuzzy2DepositAmount(uint256 depositAmount) public {
    // //         mockToken1.transfer(alice, 10e18);
    // //         mockToken2.transfer(bob, depositAmount);
    // //         vm.startPrank(alice);
    // //         mockToken1.approve(address(usdoBank), 10e18);
    // //         vm.warp(1000);
    // //         usdoBank.deposit(address(mockToken1), 10e18, alice);
    // //         vm.warp(2000);
    // //         usdoBank.borrow(5000e18, alice, false, alice);
    // //         vm.stopPrank();
    // //         vm.startPrank(address(this));
    // //         MockChainLinkBadDebt mockChainLinkBadDebt = new MockChainLinkBadDebt();
    // //         JOJOOracleAdaptor jojoOracle3 = new JOJOOracleAdaptor(
    // //             address(mockChainLinkBadDebt),
    // //             20
    // //         );
    // //         usdoBank.updateOracle(address(mockToken1), address(jojoOracle3));
    // //         vm.stopPrank();
    // //         vm.startPrank(bob);
    // //         mockToken2.approve(address(usdoBank), depositAmount);
    // //         vm.warp(3000);

    // //         usdoBank.liquidate(alice, address(mockToken1), 5e18, address(mockToken2), depositAmount, bob);
    // //         vm.stopPrank();
    // //     }

    // //      function testLiquidateFuzzyLiquidator(address liquidator) public {
    // //         mockToken1.transfer(alice, 10e18);
    // //         mockToken2.transfer(liquidator, 10e18);
    // //         vm.startPrank(alice);
    // //         mockToken1.approve(address(usdoBank), 10e18);
    // //         vm.warp(1000);
    // //         usdoBank.deposit(address(mockToken1), 10e18, alice);
    // //         vm.warp(2000);
    // //         usdoBank.borrow(5000e18, alice, false, alice);
    // //         vm.stopPrank();
    // //         vm.startPrank(address(this));
    // //         MockChainLinkBadDebt mockChainLinkBadDebt = new MockChainLinkBadDebt();
    // //         JOJOOracleAdaptor jojoOracle3 = new JOJOOracleAdaptor(
    // //             address(mockChainLinkBadDebt),
    // //             20
    // //         );
    // //         usdoBank.updateOracle(address(mockToken1), address(jojoOracle3));
    // //         vm.stopPrank();

    // //         vm.startPrank(liquidator);
    // //         mockToken2.approve(address(usdoBank), 10e18);
    // //         vm.warp(3000);
    // //         usdoBank.liquidate(alice, address(mockToken1), 5e18, address(mockToken2), 10e18, liquidator);
    // //         vm.stopPrank();
    // //     }
}
