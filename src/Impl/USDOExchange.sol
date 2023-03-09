/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1*/
pragma solidity ^0.8.9;

import "../Interface/IUSDOExchange.sol";
import "../utils/USDOError.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@JOJO/contracts/intf/IDealer.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// the exchange rate is 1:1
contract USDOExchange is IUSDOExchange, Ownable {
    using SafeERC20 for IERC20;

    //        primary asset address
    address public immutable primaryAsset;
    address public immutable USDO;

    bool public isExchangeOpen;

    //    ---------------event-----------------
    event BuyUSDO(uint256 amount, address indexed to, address indexed payer);

    //    --------------------operator-----------------------

    constructor(address _USDC, address _USDO) {
        primaryAsset = _USDC;
        USDO = _USDO;
        isExchangeOpen = true;
    }

    function closeExchange() external onlyOwner {
        isExchangeOpen = false;
    }

    function openExchange() external onlyOwner {
        isExchangeOpen = true;
    }

    function buyUSDO(uint256 amount, address to) external {
        require(isExchangeOpen, USDOErrors.NOT_ALLOWED_TO_EXCHANGE);
        IERC20(primaryAsset).safeTransferFrom(msg.sender, owner(), amount);
        IERC20(USDO).safeTransfer(to, amount);
        emit BuyUSDO(amount, to, msg.sender);
    }
}
