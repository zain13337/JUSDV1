/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1*/

pragma solidity 0.8.9;

import "../Interface/IPriceChainLink.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { IChainLinkAggregator } from "../Interface/IChainLinkAggregator.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../lib/JOJOConstant.sol";

contract JOJOOracleAdaptorWstETH is IPriceChainLink, Ownable {
    address public immutable chainlink;
    uint256 public immutable decimalsCorrection;
    uint256 public immutable heartbeatInterval;
    uint256 public immutable USDCHeartbeat;
    address public immutable USDCSource;
    address public immutable ETHSource;
    uint256 public immutable ETHHeartbeat;

    constructor(address _source, uint256 _decimalCorrection, uint256 _heartbeatInterval, address _USDCSource,
        uint256 _USDCHeartbeat, address _ETHSource, uint256 _ETHHeartbeat) {
        chainlink = _source;
        decimalsCorrection = 10 ** _decimalCorrection;
        heartbeatInterval = _heartbeatInterval;
        USDCHeartbeat = _USDCHeartbeat;
        USDCSource = _USDCSource;
        ETHSource = _ETHSource;
        ETHHeartbeat = _ETHHeartbeat;
    }

    function getAssetPrice() external view override returns (uint256) {
        /*uint80 roundID*/
        (, int256 price,, uint256 updatedAt,) = IChainLinkAggregator(chainlink).latestRoundData();
        (, int256 USDCPrice,, uint256 USDCUpdatedAt,) = IChainLinkAggregator(USDCSource).latestRoundData();
        (, int256 ETHPrice,, uint256 ETHUpdatedAt,) = IChainLinkAggregator(ETHSource).latestRoundData();

        require(block.timestamp - updatedAt <= heartbeatInterval, "ORACLE_HEARTBEAT_FAILED");
        require(block.timestamp - USDCUpdatedAt <= USDCHeartbeat, "USDC_ORACLE_HEARTBEAT_FAILED");
        require(block.timestamp - ETHUpdatedAt <= ETHHeartbeat, "ETH_ORACLE_HEARTBEAT_FAILED");
        uint256 tokenPrice = (SafeCast.toUint256(price) * SafeCast.toUint256(ETHPrice) / JOJOConstant.ONE) * 1e8 / SafeCast.toUint256(USDCPrice);
        return tokenPrice * JOJOConstant.ONE / decimalsCorrection;
    }
}
