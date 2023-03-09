// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "ds-test/test.sol";

import "../../src/Impl/USDOBank.sol";
import "../../src/Impl/USDOExchange.sol";
import "@JOJO/contracts/testSupport/TestERC20.sol";
import "../mocks/MockERC20.sol";
import "../mocks/KT.sol";
import "../../src/token/USDO.sol";
import "../../src/Impl/JOJOOracleAdaptor.sol";
import "../mocks/MockChainLink.t.sol";
import "../mocks/MockChainLink2.sol";
import "../../src/support/SupportsDODO.sol";
import "../mocks/MockChainLink500.sol";
import "../mocks/MockJOJODealer.sol";
import "../mocks/MockChainLinkBadDebt.sol";
import "../../src/lib/DataTypes.sol";
import {Utils} from "../utils/Utils.sol";
import "forge-std/Test.sol";

interface Cheats {
    function expectRevert() external;

    function expectRevert(bytes calldata) external;
}

contract USDOBankInitTest is Test {
    Cheats internal constant cheats =
        Cheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    uint256 public constant ONE = 1e18;

    Utils internal utils;
    address deployAddress;

    USDOBank public usdoBank;
    KT public mockToken2;
    MockERC20 public mockToken1;
    USDOExchange public usdoExchange;

    USDO public usdo;
    JOJOOracleAdaptor public jojoOracle1;
    JOJOOracleAdaptor public jojoOracle2;
    MockChainLink public mockToken1ChainLink;
    MockChainLink2 public mockToken2ChainLink;
    MockJOJODealer public jojoDealer;
    SupportsDODO public dodo;
    TestERC20 public USDC;
    address payable[] internal users;
    address internal alice;
    address internal bob;
    address internal insurance;
    address internal jim;

    function setUp() public {
        mockToken2 = new KT();
        mockToken1 = new MockERC20(5000e18);

        usdo = new USDO(6);
        mockToken1ChainLink = new MockChainLink();
        mockToken2ChainLink = new MockChainLink2();

        jojoDealer = new MockJOJODealer();
        jojoOracle1 = new JOJOOracleAdaptor(
            address(mockToken1ChainLink),
            20,
            86400
        );
        jojoOracle2 = new JOJOOracleAdaptor(
            address(mockToken2ChainLink),
            10,
            86400
        );
        // mock users
        utils = new Utils();
        users = utils.createUsers(5);
        alice = users[0];
        vm.label(alice, "Alice");
        bob = users[1];
        vm.label(bob, "Bob");
        insurance = users[2];
        vm.label(insurance, "Insurance");
        jim = users[3];
        vm.label(jim, "Jim");
        usdo.mint(200000e18);
        usdo.mint(10000e18);
        USDC = new TestERC20("USDC", "USDC", 6);
        // initial
        usdoBank = new USDOBank( // maxReservesAmount_
            10,
            insurance,
            address(usdo),
            address(jojoDealer),
            // maxBorrowAmountPerAccount_
            100000000000,
            // maxBorrowAmount_
            100000000001,
            // borrowFeeRate_
            2e16,
            address(USDC)
        );
        deployAddress = usdoBank.owner();

        usdo.transfer(address(usdoBank), 200000e18);
        //  mockToken2 BTC mockToken1 ETH
        usdoBank.initReserve(
            // token
            address(mockToken2),
            // initialMortgageRate
            7e17,
            // maxDepositAmount
            300e8,
            // maxDepositAmountPerAccount
            210e8,
            // maxBorrowValue
            100000e6,
            // liquidateMortgageRate
            8e17,
            // liquidationPriceOff
            5e16,
            // insuranceFeeRate
            1e17,
            address(jojoOracle2)
        );

        usdoBank.initReserve(
            // token
            address(mockToken1),
            // initialMortgageRate
            8e17,
            // maxDepositAmount
            4000e18,
            // maxDepositAmountPerAccount
            2030e18,
            // maxBorrowValue
            100000e6,
            // liquidateMortgageRate
            825e15,
            // liquidationPriceOff
            5e16,
            // insuranceFeeRate
            1e17,
            address(jojoOracle1)
        );

        dodo = new SupportsDODO(
            address(USDC),
            address(mockToken1),
            address(jojoOracle1)
        );
        address[] memory dodoList = new address[](1);
        dodoList[0] = address(dodo);
        uint256[] memory amountList = new uint256[](1);
        amountList[0] = 100000e6;
        USDC.mint(dodoList, amountList);

        usdoExchange = new USDOExchange(address(USDC), address(usdo));
        usdo.transfer(address(usdoExchange), 100000e6);
    }

    function testOwner() public {
        assertEq(deployAddress, usdoBank.owner());
    }

    function testInitMint() public {
        assertEq(usdo.balanceOf(address(usdoBank)), 200000e18);
    }
}
