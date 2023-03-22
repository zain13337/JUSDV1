/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1*/

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../src/Interface/IJUSDBank.sol";
import "../../src/Interface/IJUSDExchange.sol";

pragma solidity 0.8.9;

contract GeneralRepay {
    address public immutable USDC;
    address public usdoBank;
    address public usdoExchange;
    address public immutable JUSD;

    using SafeERC20 for IERC20;

    constructor(
        address _usdoBank,
        address _usdoExchange,
        address _USDC,
        address _JUSD
    ) {
        usdoBank = _usdoBank;
        usdoExchange = _usdoExchange;
        USDC = _USDC;
        JUSD = _JUSD;
    }

    function repayJUSD(
        address asset,
        uint256 amount,
        address to,
        bytes memory param
    ) external {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        if (asset != USDC) {
            (address approveTarget, address swapTarget, bytes memory data) = abi
                .decode(param, (address, address, bytes));
            IERC20(asset).approve(approveTarget, amount);
            (bool success, ) = swapTarget.call(data);
            if (success == false) {
                assembly {
                    let ptr := mload(0x40)
                    let size := returndatasize()
                    returndatacopy(ptr, 0, size)
                    revert(ptr, size)
                }
            }
        }

        uint256 USDCAmount = IERC20(USDC).balanceOf(address(this));
        uint256 JUSDAmount = USDCAmount;

        uint256 borrowBalance = IJUSDBank(usdoBank).getBorrowBalance(to);
        if (USDCAmount <= borrowBalance) {
            IERC20(USDC).approve(usdoExchange, USDCAmount);
            IJUSDExchange(usdoExchange).buyJUSD(USDCAmount, address(this));
        } else {
            IERC20(USDC).approve(usdoExchange, borrowBalance);
            IJUSDExchange(usdoExchange).buyJUSD(borrowBalance, address(this));
            IERC20(USDC).safeTransfer(to, USDCAmount - borrowBalance);
            JUSDAmount = borrowBalance;
        }

        IERC20(JUSD).approve(usdoBank, JUSDAmount);
        IJUSDBank(usdoBank).repay(JUSDAmount, to);
    }
}
