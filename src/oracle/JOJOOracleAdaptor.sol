/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1*/

pragma solidity 0.8.9;

import "../Interface/IPriceChainLink.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { IChainLinkAggregator } from "../Interface/IChainLinkAggregator.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../lib/JOJOConstant.sol";
import "../utils/JUSDError.sol";

contract JOJOOracleAdaptor is IPriceChainLink, Ownable {
    address public immutable chainlink;
    uint256 public immutable decimalsCorrection;
    uint256 public immutable heartbeatInterval;
    address public immutable USDCSource;

    constructor(address _source, uint256 _decimalCorrection, uint256 _heartbeatInterval, address _USDCSource) {
        chainlink = _source;
        decimalsCorrection = 10 ** _decimalCorrection;
        heartbeatInterval = _heartbeatInterval;
        USDCSource = _USDCSource;
    }

    function getAssetPrice() external view override returns (uint256) {
        /*uint80 roundID*/
        (uint80 roundID, int256 rawPrice, , uint256 updatedAt, uint80 answeredInRound) = IChainLinkAggregator(chainlink).latestRoundData();
        (uint80 USDCRoundID, int256 USDCPrice, , uint256 USDCUpdatedAt, uint80 USDCAnsweredInRound) = IChainLinkAggregator(USDCSource).latestRoundData();
        require(rawPrice> 0, JUSDErrors.CHAINLINK_PRICE_LESS_THAN_0);
        require(answeredInRound >= roundID, JUSDErrors.STALE_PRICE);
        require(USDCPrice> 0, JUSDErrors.USDC_CHAINLINK_PRICE_LESS_THAN_0);
        require(USDCAnsweredInRound >= USDCRoundID, JUSDErrors.USDC_STALE_PRICE);

        require(block.timestamp - updatedAt <= heartbeatInterval, "ORACLE_HEARTBEAT_FAILED");
        require(block.timestamp - USDCUpdatedAt <= heartbeatInterval, "USDC_ORACLE_HEARTBEAT_FAILED");
        uint256 tokenPrice = (SafeCast.toUint256(rawPrice) * 1e8) / SafeCast.toUint256(USDCPrice);
        return tokenPrice * JOJOConstant.ONE / decimalsCorrection;
    }
}
