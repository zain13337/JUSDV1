/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0*/
pragma solidity 0.8.9;

interface IPriceChainLink {
    //    get token address price
    function getAssetPrice() external view returns (uint256);
}
