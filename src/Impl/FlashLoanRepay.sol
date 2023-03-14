/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1*/
pragma solidity 0.8.9;

import "../../src/Interface/IUSDOBank.sol";
import "../../src/Interface/IUSDOExchange.sol";
import "../../src/Interface/IFlashLoanReceive.sol";
import { DecimalMath } from "../lib/DecimalMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FlashLoanRepay is IFlashLoanReceive {
    using SafeERC20 for IERC20;
    using DecimalMath for uint256;

    address public usdoBank;
    address public usdoExchange;
    address public immutable USDC;
    address public immutable USDO;

    constructor(address _usdoBank, address _usdoExchange, address _USDC, address _USDO) {
        usdoBank = _usdoBank;
        usdoExchange = _usdoExchange;
        USDC = _USDC;
        USDO = _USDO;
    }

    function JOJOFlashLoan(address asset, uint256 amount, address to, bytes calldata param) external {
        (address approveTarget, address swapTarget, bytes memory data) = abi.decode(param, (address, address, bytes));
        IERC20(asset).approve(approveTarget, amount);
        (bool success,) = swapTarget.call(data);
        if (success == false) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
        uint256 USDCAmount = IERC20(USDC).balanceOf(address(this));
        uint256 USDOAmount = USDCAmount;

        uint256 borrowBalance = IUSDOBank(usdoBank).getBorrowBalance(to);
        if (USDCAmount <= borrowBalance) {
            IERC20(USDC).approve(usdoExchange, USDCAmount);
            IUSDOExchange(usdoExchange).buyUSDO(USDCAmount, address(this));
        } else {
            IERC20(USDC).approve(usdoExchange, borrowBalance);
            IUSDOExchange(usdoExchange).buyUSDO(borrowBalance, address(this));
            IERC20(USDC).safeTransfer(to, USDCAmount - borrowBalance);
            USDOAmount = borrowBalance;
        }

        IERC20(USDO).approve(usdoBank, USDOAmount);
        IUSDOBank(usdoBank).repay(USDOAmount, to);
    }
}
