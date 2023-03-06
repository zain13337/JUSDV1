/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0*/
pragma solidity 0.8.9;

import "../../src/Interface/IUSDOBank.sol";
import "../../src/Interface/IUSDOExchange.sol";
import "../../src/Interface/IFlashLoanReceive.sol";
import { DecimalMath } from "../../src/lib/DecimalMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IPriceChainLink } from "../../src/Interface/IPriceChainLink.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LiquidateCollateralRepayNotEnough is IFlashLoanReceive {
    using SafeERC20 for IERC20;
    using DecimalMath for uint256;

    address public usdoBank;
    address public usdoExchange;
    address public immutable USDC;
    address public immutable USDO;
    address public insurance;

    struct LiquidateData {
        uint256 actualCollateral;
        uint256 insuranceFee;
        uint256 actualLiquidatedT0;
        uint256 actualLiquidated;
        uint256 liquidatedRemainUSDC;
    }

    constructor(address _usdoBank, address _usdoExchange, address _USDC, address _USDO, address _insurance) {
        usdoBank = _usdoBank;
        usdoExchange = _usdoExchange;
        USDC = _USDC;
        USDO = _USDO;
        insurance = _insurance;
    }

    function JOJOFlashLoan(address asset, uint256 amount, address to, bytes calldata param) external {
        //dodo swap
        (LiquidateData memory liquidateData, bytes memory originParam) = abi.decode(param, (LiquidateData, bytes));
        (address approveTarget, address swapTarget,, bytes memory data) =
            abi.decode(originParam, (address, address, address, bytes));
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

        IERC20(USDC).approve(usdoExchange, liquidateData.actualLiquidated - 1);
        IUSDOExchange(usdoExchange).buyUSDO(liquidateData.actualLiquidated - 1, address(this));
        IERC20(USDO).approve(usdoBank, liquidateData.actualLiquidated - 1);
        IUSDOBank(usdoBank).repay(liquidateData.actualLiquidated - 1, to);
    }
}

contract LiquidateCollateralInsuranceNotEnough is IFlashLoanReceive {
    using SafeERC20 for IERC20;
    using DecimalMath for uint256;

    address public usdoBank;
    address public usdoExchange;
    address public immutable USDC;
    address public immutable USDO;
    address public insurance;

    struct LiquidateData {
        uint256 actualCollateral;
        uint256 insuranceFee;
        uint256 actualLiquidatedT0;
        uint256 actualLiquidated;
        uint256 liquidatedRemainUSDC;
    }

    constructor(address _usdoBank, address _usdoExchange, address _USDC, address _USDO, address _insurance) {
        usdoBank = _usdoBank;
        usdoExchange = _usdoExchange;
        USDC = _USDC;
        USDO = _USDO;
        insurance = _insurance;
    }

    function JOJOFlashLoan(address asset, uint256 amount, address to, bytes calldata param) external {
        //dodo swap
        (LiquidateData memory liquidateData, bytes memory originParam) = abi.decode(param, (LiquidateData, bytes));
        (address approveTarget, address swapTarget,, bytes memory data) =
            abi.decode(originParam, (address, address, address, bytes));
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

        IERC20(USDC).approve(usdoExchange, liquidateData.actualLiquidated);
        IUSDOExchange(usdoExchange).buyUSDO(liquidateData.actualLiquidated, address(this));
        IERC20(USDO).approve(usdoBank, liquidateData.actualLiquidated);
        IUSDOBank(usdoBank).repay(liquidateData.actualLiquidated, to);

        // 2. insurance
        IERC20(USDC).transfer(insurance, liquidateData.insuranceFee - 1);

        // 3. liquidate usdc
        if (liquidateData.liquidatedRemainUSDC != 0) {
            IERC20(USDC).transfer(to, liquidateData.liquidatedRemainUSDC - 1);
        }
    }
}

contract LiquidateCollateralLiquidatedNotEnough is IFlashLoanReceive {
    using SafeERC20 for IERC20;
    using DecimalMath for uint256;

    address public usdoBank;
    address public usdoExchange;
    address public immutable USDC;
    address public immutable USDO;
    address public insurance;

    struct LiquidateData {
        uint256 actualCollateral;
        uint256 insuranceFee;
        uint256 actualLiquidatedT0;
        uint256 actualLiquidated;
        uint256 liquidatedRemainUSDC;
    }

    constructor(address _usdoBank, address _usdoExchange, address _USDC, address _USDO, address _insurance) {
        usdoBank = _usdoBank;
        usdoExchange = _usdoExchange;
        USDC = _USDC;
        USDO = _USDO;
        insurance = _insurance;
    }

    function JOJOFlashLoan(address asset, uint256 amount, address to, bytes calldata param) external {
        //dodo swap
        (LiquidateData memory liquidateData, bytes memory originParam) = abi.decode(param, (LiquidateData, bytes));
        (address approveTarget, address swapTarget,, bytes memory data) =
            abi.decode(originParam, (address, address, address, bytes));
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

        IERC20(USDC).approve(usdoExchange, liquidateData.actualLiquidated);
        IUSDOExchange(usdoExchange).buyUSDO(liquidateData.actualLiquidated, address(this));
        IERC20(USDO).approve(usdoBank, liquidateData.actualLiquidated);
        IUSDOBank(usdoBank).repay(liquidateData.actualLiquidated, to);

        // 2. insurance
        IERC20(USDC).transfer(insurance, liquidateData.insuranceFee);

        // 3. liquidate usdc
        if (liquidateData.liquidatedRemainUSDC != 0) {
            IERC20(USDC).transfer(to, liquidateData.liquidatedRemainUSDC - 1);
        }
    }
}
