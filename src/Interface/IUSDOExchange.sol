/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1*/

pragma solidity 0.8.9;

/// @notice USDOExchange is an exchange system that allow users to exchange USDC to USDO in 1:1
interface IUSDOExchange {
    /// @notice in buyUSDO function, users can buy USDO using USDC
    /// @param amount: the amount of USDO the users want to buy
    /// @param to: the USDO transfer to which address
    function buyUSDO(uint256 amount, address to) external;
}
