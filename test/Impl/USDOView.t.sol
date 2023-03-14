// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "@JOJO/contracts/testSupport/TestERC20.sol";

import "./USDOBankInit.t.sol";

contract USDOViewTest is USDOBankInitTest {
    function testUSDOView() public {
        TestERC20 BTC = new TestERC20("BTC", "BTC", 8);

        jojoOracle2 = new JOJOOracleAdaptor(
            address(mockToken1ChainLink),
            10,
            86400
        );
        usdoBank.initReserve(
            // token
            address(BTC),
            // maxCurrencyBorrowRate
            7e17,
            // maxDepositAmount
            2100e8,
            // maxDepositAmountPerAccount
            210e8,
            // maxBorrowValue
            100000e18,
            // liquidateMortgageRate
            75e16,
            // liquidationPriceOff
            1e17,
            // insuranceFeeRate
            1e17,
            address(jojoOracle2)
        );
        uint256 btcPrice = IPriceChainLink(address(jojoOracle2)).getAssetPrice();
        console.log("btcPrice", btcPrice);
        address[] memory user = new address[](1);
        user[0] = address(alice);
        uint256[] memory amountList = new uint256[](1);
        amountList[0] = 10e8;
        BTC.mint(user, amountList);
        mockToken1.transfer(alice, 100e18);

        vm.startPrank(alice);

        BTC.approve(address(usdoBank), 1e8);
        mockToken1.approve(address(usdoBank), 10e18);
        usdoBank.deposit(alice, address(mockToken1), 10e18, alice);
        usdoBank.deposit(alice, address(BTC), 1e8, alice);

        uint256 maxMintAmount = usdoBank.getDepositMaxMintAmount(alice);
        uint256 maxWithdrawBTC = usdoBank.getMaxWithdrawAmount(address(BTC), alice);
        uint256 maxWithdrawETH = usdoBank.getMaxWithdrawAmount(address(mockToken1), alice);
        assertEq(maxMintAmount, 8700000000);
        assertEq(maxWithdrawBTC, 1e8);
        assertEq(maxWithdrawETH, 10e18);

        usdoBank.borrow(7200e6, alice, false);
        maxWithdrawBTC = usdoBank.getMaxWithdrawAmount(address(BTC), alice);
        maxWithdrawETH = usdoBank.getMaxWithdrawAmount(address(mockToken1), alice);
        assertEq(maxWithdrawBTC, 100000000);
        assertEq(maxWithdrawETH, 1875000000000000000);

        usdoBank.borrow(800e6, alice, false);
        usdoBank.withdraw(address(BTC), 1e8, alice, false);
        maxWithdrawETH = usdoBank.getMaxWithdrawAmount(address(mockToken1), alice);
        assertEq(maxWithdrawETH, 0);
    }
}
