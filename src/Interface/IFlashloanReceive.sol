/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0*/
pragma solidity 0.8.9;

interface IFlashLoanReceive {
    function JOJOFlashLoan(address asset, uint256 amount, address to, bytes calldata param) external;
}
