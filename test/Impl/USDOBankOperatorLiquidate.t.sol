// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "ds-test/test.sol";
import "../../src/Impl/USDOBank.sol";
import "../mocks/MockERC20.sol";
import "../../src/token/USDO.sol";
import "../../src/support/SupportsDODO.sol";
import "../mocks/MockChainLink500.sol";
import "../../src/Impl/JOJOOracleAdaptor.sol";
import "../../src/Impl/FlashLoanLiquidate.sol";
import "../mocks/MockChainLink.t.sol";
import "../mocks/MockJOJODealer.sol";
import "../../src/lib/DataTypes.sol";
import "@JOJO/contracts/subaccount/Subaccount.sol";
import "@JOJO/contracts/impl/JOJODealer.sol";
import "@JOJO/contracts/subaccount/SubaccountFactory.sol";
import "@JOJO/contracts/testSupport/TestERC20.sol";
import { console } from "forge-std/console.sol";
import "forge-std/Test.sol";
import "../../src/Impl/USDOExchange.sol";
import "../mocks/MockChainLinkBadDebt.sol";
import "../../src/lib/DecimalMath.sol";
import "../mocks/MockChainLink900.sol";
import "../mocks/MockUSDCPrice.sol";
import {
    LiquidateCollateralRepayNotEnough,
    LiquidateCollateralInsuranceNotEnough,
    LiquidateCollateralLiquidatedNotEnough
} from "../mocks/MockWrongLiquidateFlashloan.sol";

interface Cheats {
    function expectRevert() external;

    function expectRevert(bytes calldata) external;
}

contract USDOBankOperatorLiquidateTest is Test {
    Cheats internal constant cheats = Cheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    using DecimalMath for uint256;

    USDOBank public usdoBank;
    MockERC20 public ETH;
    TestERC20 public USDC;
    USDO public usdo;
    JOJOOracleAdaptor public jojoOracleETH;
    MockChainLink public ethChainLink;
    MockUSDCPrice public usdcPrice;
    JOJODealer public jojoDealer;
    USDOExchange public usdoExchange;
    SupportsDODO public dodo;

    address internal alice = address(1);
    address internal bob = address(2);
    address internal insurance = address(3);

    function setUp() public {
        ETH = new MockERC20(2000e18);
        usdo = new USDO(6);
        USDC = new TestERC20("USDC", "USDC", 6);
        ethChainLink = new MockChainLink();
        usdcPrice = new MockUSDCPrice();
        jojoDealer = new JOJODealer(address(USDC));
        jojoOracleETH = new JOJOOracleAdaptor(address(ethChainLink), 20, 86400, address(usdcPrice));
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(insurance, "Insurance");
        usdo.mint(300000e6);
        usdoExchange = new USDOExchange(address(USDC), address(usdo));
        usdo.transfer(address(usdoExchange), 100000e6);
        usdoBank = new USDOBank( // maxReservesAmount_
            10,
            insurance,
            address(usdo),
            address(jojoDealer),
            // maxBorrowAmountPerAccount_
            100000000000,
            // maxBorrowAmount_
            1000000000000,
            2e16,
            address(USDC)
        );

        usdo.transfer(address(usdoBank), 100000e6);

        dodo = new SupportsDODO(
            address(USDC),
            address(ETH),
            address(jojoOracleETH)
        );
        address[] memory dodoList = new address[](1);
        dodoList[0] = address(dodo);
        uint256[] memory amountList = new uint256[](1);
        amountList[0] = 10000e6;
        USDC.mint(dodoList, amountList);
        IERC20(usdo).transfer(address(usdoExchange), 5000e6);

        usdoBank.initReserve(
            // token
            address(ETH),
            // maxCurrencyBorrowRate
            8e17,
            // maxDepositAmount
            20300e18,
            // maxDepositAmountPerAccount
            2030e18,
            // maxBorrowValue
            100000e18,
            // liquidateMortgageRate
            825e15,
            // liquidationPriceOff
            5e16,
            // insuranceFeeRate
            1e17,
            address(jojoOracleETH)
        );
    }

    // all liquidate

    function testLiquidateAll() public {
        ETH.transfer(alice, 10e18);
        vm.startPrank(alice);
        ETH.approve(address(usdoBank), 10e18);

        // eth 10 0.8 1000 8000
        usdoBank.deposit(alice, address(ETH), 10e18, alice);
        vm.warp(1000);
        usdoBank.borrow(7426e6, alice, false);
        vm.stopPrank();

        // price exchange 900 * 10 * 0.825 = 7425
        // liquidateAmount = 7695, USDJBorrow 7426 liquidationPriceOff = 0.05 priceOff = 855 actualUSDO = 8,251.1111111111 insuranceFee = 8,25.11111111111
        // actualCollateral 9.6504223522
        vm.warp(2000);
        MockChainLink900 eth900 = new MockChainLink900();
        JOJOOracleAdaptor jojoOracle900 = new JOJOOracleAdaptor(
            address(eth900),
            20,
            86400,
            address(usdcPrice)
        );
        usdoBank.updateOracle(address(ETH), address(jojoOracle900));
        dodo.addTokenPrice(address(ETH), address(jojoOracle900));

        //init flashloanRepay
        usdo.mint(50000e6);
        IERC20(usdo).transfer(address(usdoExchange), 50000e6);
        FlashLoanLiquidate flashLoanLiquidate = new FlashLoanLiquidate(
            address(usdoBank),
            address(usdoExchange),
            address(USDC),
            address(usdo),
            insurance
        );

        bytes memory data = dodo.getSwapData(10e18, address(ETH));
        bytes memory param = abi.encode(dodo, dodo, address(bob), data);

        // liquidate

        vm.startPrank(bob);

        uint256 aliceUsedBorrowed = usdoBank.getBorrowBalance(alice);
        bytes memory afterParam = abi.encode(address(flashLoanLiquidate), param);
        DataTypes.LiquidateData memory liq = usdoBank.liquidate(alice, address(ETH), bob, 10e18, afterParam, 0);

        //judge
        uint256 bobDeposit = usdoBank.getDepositBalance(address(ETH), bob);
        uint256 aliceDeposit = usdoBank.getDepositBalance(address(ETH), alice);
        uint256 bobBorrow = usdoBank.getBorrowBalance(bob);
        uint256 aliceBorrow = usdoBank.getBorrowBalance(alice);
        uint256 insuranceUSDC = IERC20(USDC).balanceOf(insurance);
        uint256 aliceUSDC = IERC20(USDC).balanceOf(alice);
        uint256 bobUSDC = IERC20(USDC).balanceOf(bob);
        console.log((((aliceUsedBorrowed * 1e18) / 855000000) * 1e18) / 9e17);
        console.log((((aliceUsedBorrowed * 1e17) / 1e18) * 1e18) / 9e17);
        console.log(((10e18 - liq.actualCollateral) * 900e6) / 1e18);
        console.log((((liq.actualCollateral * 900e6) / 1e18) * 5e16) / 1e18);

        assertEq(aliceDeposit, 0);
        assertEq(bobDeposit, 0);
        assertEq(bobBorrow, 0);
        assertEq(aliceBorrow, 0);
        assertEq(liq.actualCollateral, 9650428473034437946);
        assertEq(insuranceUSDC, 825111634);
        assertEq(aliceUSDC, 314614374);
        assertEq(bobUSDC, 434269282);

        // logs
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

    function testLiquidatePart() public {
        ETH.transfer(alice, 10e18);
        vm.startPrank(alice);
        ETH.approve(address(usdoBank), 10e18);

        // eth 10 0.8 1000 8000
        usdoBank.deposit(alice, address(ETH), 10e18, alice);
        vm.warp(1000);
        usdoBank.borrow(7426e6, alice, false);
        vm.stopPrank();

        // price exchange 900 * 10 * 0.825 = 7425
        // liquidateAmount = 7695, USDJBorrow 7426 liquidationPriceOff = 0.05 priceOff = 855 actualUSDO = 8,251.1111111111 insuranceFee = 8,25.11111111111
        // actualCollateral 9.6504223522
        vm.warp(2000);
        MockChainLink900 eth900 = new MockChainLink900();
        JOJOOracleAdaptor jojoOracle900 = new JOJOOracleAdaptor(
            address(eth900),
            20,
            86400,
            address(usdcPrice)
        );
        usdoBank.updateOracle(address(ETH), address(jojoOracle900));
        dodo.addTokenPrice(address(ETH), address(jojoOracle900));

        //init flashloanRepay
        usdo.mint(50000e6);
        IERC20(usdo).transfer(address(usdoExchange), 50000e6);
        FlashLoanLiquidate flashLoanLiquidate = new FlashLoanLiquidate(
            address(usdoBank),
            address(usdoExchange),
            address(USDC),
            address(usdo),
            insurance
        );
        // flashLoanLiquidate.setOracle(address(ETH), address(jojoOracle900));

        bytes memory data = dodo.getSwapData(5e18, address(ETH));
        bytes memory param = abi.encode(dodo, dodo, address(bob), data);

        // liquidate

        vm.startPrank(bob);

        uint256 aliceUsedBorrowed = usdoBank.getBorrowBalance(alice);
        bytes memory afterParam = abi.encode(address(flashLoanLiquidate), param);
        DataTypes.LiquidateData memory liq = usdoBank.liquidate(alice, address(ETH), bob, 5e18, afterParam, 0);

        assertEq(usdoBank.isAccountSafe(alice), true);

        //judge
        uint256 bobDeposit = usdoBank.getDepositBalance(address(ETH), bob);
        uint256 aliceDeposit = usdoBank.getDepositBalance(address(ETH), alice);
        uint256 bobBorrow = usdoBank.getBorrowBalance(bob);
        uint256 aliceBorrow = usdoBank.getBorrowBalance(alice);
        uint256 insuranceUSDC = IERC20(USDC).balanceOf(insurance);
        uint256 aliceUSDC = IERC20(USDC).balanceOf(alice);
        uint256 bobUSDC = IERC20(USDC).balanceOf(bob);
        console.log((((5e18 * 855000000) / 1e18) * 9e17) / 1e18);
        // console.log((aliceUsedBorrowed * 1e17 / 1e18)* 1e18 / 9e17);
        console.log((((liq.actualCollateral * 900e6) / 1e18) * 5e16) / 1e18);

        assertEq(aliceDeposit, 5e18);
        assertEq(bobDeposit, 0);
        assertEq(bobBorrow, 0);
        assertEq(aliceBorrow, aliceUsedBorrowed - 3847500000);
        assertEq(liq.actualCollateral, 5e18);
        assertEq(insuranceUSDC, 427500000);
        assertEq(aliceUSDC, 0);
        assertEq(bobUSDC, 225000000);

        // logs
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

    /// @notice user borrow usdo account is not safe
    function testHandleDebt() public {
        ETH.transfer(alice, 10e18);
        vm.startPrank(alice);
        ETH.approve(address(usdoBank), 10e18);

        // eth 10 0.8 1000 8000
        usdoBank.deposit(alice, address(ETH), 10e18, alice);
        vm.warp(1000);
        usdoBank.borrow(7426e6, alice, false);
        vm.stopPrank();

        // price exchange 900 * 10 * 0.825 = 7425
        // liquidateAmount = 7695, USDJBorrow 7426 liquidationPriceOff = 0.05 priceOff = 855 actualUSDO = 8,251.1111111111 insuranceFee = 8,25.11111111111
        // actualCollateral 9.6504223522
        vm.warp(2000);

        MockChainLink500 eth500 = new MockChainLink500();
        JOJOOracleAdaptor jojoOracle500 = new JOJOOracleAdaptor(
            address(eth500),
            20,
            86400,
            address(usdcPrice)
        );
        usdoBank.updateOracle(address(ETH), address(jojoOracle500));
        dodo.addTokenPrice(address(ETH), address(jojoOracle500));

        //init flashloanRepay
        usdo.mint(50000e6);
        IERC20(usdo).transfer(address(usdoExchange), 50000e6);
        FlashLoanLiquidate flashLoanLiquidate = new FlashLoanLiquidate(
            address(usdoBank),
            address(usdoExchange),
            address(USDC),
            address(usdo),
            insurance
        );

        bytes memory data = dodo.getSwapData(10e18, address(ETH));
        bytes memory param = abi.encode(dodo, dodo, address(bob), data);

        // liquidate

        vm.startPrank(bob);

        uint256 aliceUsedBorrowed = usdoBank.getBorrowBalance(alice);
        bytes memory afterParam = abi.encode(address(flashLoanLiquidate), param);
        DataTypes.LiquidateData memory liq = usdoBank.liquidate(alice, address(ETH), bob, 10e18, afterParam, 0);

        //judge
        uint256 bobDeposit = usdoBank.getDepositBalance(address(ETH), bob);
        uint256 aliceDeposit = usdoBank.getDepositBalance(address(ETH), alice);
        uint256 bobBorrow = usdoBank.getBorrowBalance(bob);
        uint256 aliceBorrow = usdoBank.getBorrowBalance(alice);
        uint256 insuranceUSDC = IERC20(USDC).balanceOf(insurance);
        uint256 aliceUSDC = IERC20(USDC).balanceOf(alice);
        uint256 bobUSDC = IERC20(USDC).balanceOf(bob);
        uint256 insuranceBorrow = usdoBank.getBorrowBalance(insurance);

        assertEq(aliceDeposit, 0);
        assertEq(bobDeposit, 0);
        assertEq(bobBorrow, 0);
        assertEq(aliceBorrow, 0);
        assertEq(liq.actualCollateral, 10e18);
        assertEq(insuranceUSDC, 475000000);
        assertEq(aliceUSDC, 0);
        assertEq(bobUSDC, 250000000);
        assertEq(insuranceBorrow, aliceUsedBorrowed - 4275e6);

        // logs
        console.log("liquidate amount", liq.actualCollateral);
        console.log("bob deposit", bobDeposit);
        console.log("alice deposit", aliceDeposit);
        console.log("bob borrow", bobBorrow);
        console.log("alice borrow", aliceBorrow);
        console.log("bob usdc", bobUSDC);
        console.log("alice usdc", aliceUSDC);
        console.log("insurance balance", insuranceUSDC);
        console.log("insurance borrow", insuranceBorrow);
        vm.stopPrank();
        address[] memory liquidaters = new address[](1);
        liquidaters[0] = alice;
        usdoBank.handleDebt(liquidaters);
    }

    function testRepayAmountNotEnough() public {
        ETH.transfer(alice, 10e18);
        vm.startPrank(alice);
        ETH.approve(address(usdoBank), 10e18);

        usdoBank.deposit(alice, address(ETH), 10e18, alice);
        vm.warp(1000);
        usdoBank.borrow(7426e6, alice, false);
        vm.stopPrank();

        vm.warp(2000);
        MockChainLink900 eth900 = new MockChainLink900();
        JOJOOracleAdaptor jojoOracle900 = new JOJOOracleAdaptor(
            address(eth900),
            20,
            86400,
            address(usdcPrice)
        );
        usdoBank.updateOracle(address(ETH), address(jojoOracle900));
        dodo.addTokenPrice(address(ETH), address(jojoOracle900));

        //init flashloanRepay
        usdo.mint(50000e6);
        IERC20(usdo).transfer(address(usdoExchange), 50000e6);
        LiquidateCollateralRepayNotEnough flashLoanLiquidate = new LiquidateCollateralRepayNotEnough(
                address(usdoBank),
                address(usdoExchange),
                address(USDC),
                address(usdo),
                insurance
            );

        bytes memory data = dodo.getSwapData(10e18, address(ETH));
        bytes memory param = abi.encode(dodo, dodo, address(bob), data);

        // liquidate
        vm.startPrank(bob);
        bytes memory afterParam = abi.encode(address(flashLoanLiquidate), param);
        cheats.expectRevert("REPAY_AMOUNT_NOT_ENOUGH");
        usdoBank.liquidate(alice, address(ETH), bob, 10e18, afterParam, 0);
    }

    function testInsuranceAmountNotEnough() public {
        ETH.transfer(alice, 10e18);
        vm.startPrank(alice);
        ETH.approve(address(usdoBank), 10e18);

        // eth 10 0.8 1000 8000
        usdoBank.deposit(alice, address(ETH), 10e18, alice);
        vm.warp(1000);
        usdoBank.borrow(7426e6, alice, false);
        vm.stopPrank();

        vm.warp(2000);
        MockChainLink900 eth900 = new MockChainLink900();
        JOJOOracleAdaptor jojoOracle900 = new JOJOOracleAdaptor(
            address(eth900),
            20,
            86400,
            address(usdcPrice)
        );
        usdoBank.updateOracle(address(ETH), address(jojoOracle900));
        dodo.addTokenPrice(address(ETH), address(jojoOracle900));

        //init flashloanRepay
        usdo.mint(50000e6);
        IERC20(usdo).transfer(address(usdoExchange), 50000e6);
        LiquidateCollateralInsuranceNotEnough flashLoanLiquidate = new LiquidateCollateralInsuranceNotEnough(
                address(usdoBank),
                address(usdoExchange),
                address(USDC),
                address(usdo),
                insurance
            );

        bytes memory data = dodo.getSwapData(10e18, address(ETH));
        bytes memory param = abi.encode(dodo, dodo, address(bob), data);

        // liquidate
        vm.startPrank(bob);
        bytes memory afterParam = abi.encode(address(flashLoanLiquidate), param);
        cheats.expectRevert("INSURANCE_AMOUNT_NOT_ENOUGH");
        usdoBank.liquidate(alice, address(ETH), bob, 10e18, afterParam, 0);
    }

    function testLiquidatedAmountNotEnough() public {
        ETH.transfer(alice, 10e18);
        vm.startPrank(alice);
        ETH.approve(address(usdoBank), 10e18);

        // eth 10 0.8 1000 8000
        usdoBank.deposit(alice, address(ETH), 10e18, alice);
        vm.warp(1000);
        usdoBank.borrow(7426e6, alice, false);
        vm.stopPrank();

        vm.warp(2000);
        MockChainLink900 eth900 = new MockChainLink900();
        JOJOOracleAdaptor jojoOracle900 = new JOJOOracleAdaptor(
            address(eth900),
            20,
            86400,
            address(usdcPrice)
        );
        usdoBank.updateOracle(address(ETH), address(jojoOracle900));
        dodo.addTokenPrice(address(ETH), address(jojoOracle900));

        //init flashloanRepay
        usdo.mint(50000e6);
        IERC20(usdo).transfer(address(usdoExchange), 50000e6);
        LiquidateCollateralLiquidatedNotEnough flashLoanLiquidate = new LiquidateCollateralLiquidatedNotEnough(
                address(usdoBank),
                address(usdoExchange),
                address(USDC),
                address(usdo),
                insurance
            );

        bytes memory data = dodo.getSwapData(10e18, address(ETH));
        bytes memory param = abi.encode(dodo, dodo, address(bob), data);

        // liquidate
        vm.startPrank(bob);
        bytes memory afterParam = abi.encode(address(flashLoanLiquidate), param);
        cheats.expectRevert("LIQUIDATED_AMOUNT_NOT_ENOUGH");
        usdoBank.liquidate(alice, address(ETH), bob, 10e18, afterParam, 0);
    }

    function testFlashloanLiquidateRevert() public {
        ETH.transfer(alice, 20e18);
        vm.startPrank(alice);
        ETH.approve(address(usdoBank), 20e18);

        // eth 10 0.8 1000 8000
        usdoBank.deposit(alice, address(ETH), 20e18, alice);
        vm.warp(1000);
        usdoBank.borrow(14860e6, alice, false);
        vm.stopPrank();

        vm.warp(2000);
        MockChainLink900 eth900 = new MockChainLink900();
        JOJOOracleAdaptor jojoOracle900 = new JOJOOracleAdaptor(
            address(eth900),
            20,
            86400,
            address(usdcPrice)
        );
        usdoBank.updateOracle(address(ETH), address(jojoOracle900));
        dodo.addTokenPrice(address(ETH), address(jojoOracle900));

        //init flashloanRepay
        usdo.mint(50000e6);
        IERC20(usdo).transfer(address(usdoExchange), 50000e6);
        FlashLoanLiquidate flashLoanLiquidate = new FlashLoanLiquidate(
            address(usdoBank),
            address(usdoExchange),
            address(USDC),
            address(usdo),
            insurance
        );

        bytes memory data = dodo.getSwapData(20e18, address(ETH));
        bytes memory param = abi.encode(dodo, dodo, address(bob), data);

        // liquidate

        vm.startPrank(bob);

        bytes memory afterParam = abi.encode(address(flashLoanLiquidate), param);
        cheats.expectRevert("ERC20: transfer amount exceeds balance");
        usdoBank.liquidate(alice, address(ETH), bob, 20e18, afterParam, 0);
        vm.stopPrank();
    }
}
