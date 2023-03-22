// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "ds-test/test.sol";
import "../../src/Impl/JUSDBank.sol";
import "../mocks/MockERC20.sol";
import "../../src/token/JUSD.sol";
import "../../src/Impl/JOJOOracleAdaptor.sol";
import "../mocks/MockChainLink.t.sol";
import "../mocks/MockJOJODealer.sol";
import "../../src/lib/DataTypes.sol";
import {console} from "forge-std/console.sol";
import "forge-std/Test.sol";
import "@JOJO/contracts/testSupport/TestERC20.sol";
import "../mocks/MockUSDCPrice.sol";
import "../../src/lib/DecimalMath.sol";

interface Cheats {
    function expectRevert() external;

    function expectRevert(bytes calldata) external;
}

contract JUSDOperationTest is Test {
    Cheats internal constant cheats =
        Cheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    using DecimalMath for uint256;

    JUSDBank public usdoBank;
    MockERC20 public mockToken1;
    JUSD public usdo;
    JOJOOracleAdaptor public jojoOracle1;
    MockChainLink public mockToken1ChainLink;
    MockUSDCPrice public usdcPrice;
    MockJOJODealer public jojoDealer;
    TestERC20 public USDC;

    address internal alice = address(1);
    address internal bob = address(2);
    address internal insurance = address(3);

    function setUp() public {
        mockToken1 = new MockERC20(2000e18);
        usdo = new JUSD(6);
        mockToken1ChainLink = new MockChainLink();
        usdcPrice = new MockUSDCPrice();
        jojoDealer = new MockJOJODealer();
        jojoOracle1 = new JOJOOracleAdaptor(
            address(mockToken1ChainLink),
            20,
            86400,
            address(usdcPrice)
        );
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(insurance, "Insurance");
        usdo.mint(100000e6);
        USDC = new TestERC20("USDC", "USDC", 6);
        usdoBank = new JUSDBank( // maxReservesAmount_
            2,
            insurance,
            address(usdo),
            address(jojoDealer),
            // maxBorrowAmountPerAccount_
            6000e18,
            // maxBorrowAmount_
            9000e18,
            // borrowFeeRate_
            2e16,
            address(USDC)
        );

        usdoBank.initReserve(
            // token
            address(mockToken1),
            // maxCurrencyBorrowRate
            5e17,
            // maxDepositAmount
            180e18,
            // maxDepositAmountPerAccount
            100e18,
            // maxBorrowValue
            100000e18,
            // liquidateMortgageRate
            9e17,
            // liquidationPriceOff
            5e16,
            // insuranceFeeRate
            1e16,
            address(jojoOracle1)
        );
    }

    function testJUSDMint() public {
        usdo.mint(100e6);
        assertEq(usdo.balanceOf(address(this)), 100100e6);
    }

    function testJUSDBurn() public {
        usdo.burn(50000e6);
        assertEq(usdo.balanceOf(address(this)), 50000e6);
    }

    function testJUSDDecimal() public {
        emit log_uint(usdo.decimals());
        assertEq(usdo.decimals(), 6);
    }

    function testInitReserveParamWrong() public {
        cheats.expectRevert("RESERVE_PARAM_ERROR");
        usdoBank.initReserve(
            // token
            address(mockToken1),
            // maxCurrencyBorrowRate
            5e17,
            // maxDepositAmount
            180e18,
            // maxDepositAmountPerAccount
            100e18,
            // maxBorrowValue
            100000e18,
            // liquidateMortgageRate
            9e17,
            // liquidationPriceOff
            5e16,
            // insuranceFeeRate
            1e17,
            address(jojoOracle1)
        );
    }

    function updatePrimaryAsset() public {
        usdoBank.updatePrimaryAsset(address(123));
    }

    function testInitReserve() public {
        usdoBank.initReserve(
            // token
            address(mockToken1),
            // maxCurrencyBorrowRate
            5e17,
            // maxDepositAmount
            180e18,
            // maxDepositAmountPerAccount
            100e18,
            // maxBorrowValue
            100000e18,
            // liquidateMortgageRate
            9e17,
            // liquidationPriceOff
            5e16,
            // insuranceFeeRate
            1e16,
            address(jojoOracle1)
        );
    }

    function testInitReserveTooMany() public {
        usdoBank.updateMaxReservesAmount(0);

        cheats.expectRevert("NO_MORE_RESERVE_ALLOWED");
        usdoBank.initReserve(
            // token
            address(mockToken1),
            // maxCurrencyBorrowRate
            5e17,
            // maxDepositAmount
            180e18,
            // maxDepositAmountPerAccount
            100e18,
            // maxBorrowValue
            100000e18,
            // liquidateMortgageRate
            9e17,
            // liquidationPriceOff
            5e16,
            // insuranceFeeRate
            1e16,
            address(jojoOracle1)
        );
    }

    function testUpdateMaxBorrowAmount() public {
        usdoBank.updateMaxBorrowAmount(1000e18, 10000e18);
        assertEq(usdoBank.maxTotalBorrowAmount(), 10000e18);
    }

    function testUpdateRiskParam() public {
        usdoBank.updateRiskParam(address(mockToken1), 2e16, 2e17, 2e17);
        //        assertEq(usdoBank.getInsuranceFeeRate(address(mockToken1)), 2e17);
    }

    function testUpdateRiskParamWrong() public {
        cheats.expectRevert("RESERVE_PARAM_ERROR");
        usdoBank.updateRiskParam(address(mockToken1), 9e17, 2e17, 2e17);
        //        assertEq(usdoBank.getInsuranceFeeRate(address(mockToken1)), 2e17);
    }

    function testUpdateReserveParam() public {
        usdoBank.updateReserveParam(
            address(mockToken1),
            1e18,
            100e18,
            100e18,
            200000e18
        );
        //        assertEq(usdoBank.getInitialRate(address(mockToken1)), 1e18);
    }

    function testSetInsurance() public {
        usdoBank.updateInsurance(address(10));
        assertEq(usdoBank.insurance(), address(10));
    }

    function testSetJOJODealer() public {
        usdoBank.updateJOJODealer(address(10));
        assertEq(usdoBank.JOJODealer(), address(10));
    }

    function testSetOracle() public {
        usdoBank.updateOracle(address(mockToken1), address(10));
    }

    function testUpdateRate() public {
        usdoBank.updateBorrowFeeRate(1e18);
        assertEq(usdoBank.borrowFeeRate(), 1e18);
    }

    function testUpdatePrimaryAsset() public {
        usdoBank.updatePrimaryAsset(address(123));
        assertEq(usdoBank.primaryAsset(), address(123));
    }

    // -----------test view--------------
    function testReserveList() public {
        address[] memory list = usdoBank.getReservesList();
        assertEq(list[0], address(mockToken1));
    }

    function testCollateralPrice() public {
        uint256 price = usdoBank.getCollateralPrice(address(mockToken1));
        assertEq(price, 1e9);
    }

    function testCollateraltMaxMintAmount() public {
        uint256 value = usdoBank.getCollateralMaxMintAmount(
            address(mockToken1),
            2e18
        );
        assertEq(value, 1000e6);
    }
}
