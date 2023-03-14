/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1*/

pragma solidity 0.8.9;

import "../Interface/IPriceChainLink.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { IChainLinkAggregator } from "../Interface/IChainLinkAggregator.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../lib/JOJOConstant.sol";

contract JOJOOracleAdaptor is IPriceChainLink, Ownable {
    address public immutable source;
    uint256 public immutable decimalsCorrection;
    uint256 public immutable heartbeatInterval;

    constructor(address _source, uint256 _decimalCorrection, uint256 _heartbeatInterval) {
        source = _source;
        decimalsCorrection = 10 ** _decimalCorrection;
        heartbeatInterval = _heartbeatInterval;
    }

    function getAssetPrice() external view override returns (uint256) {
        /*uint80 roundID*/
        (, int256 price,, uint256 updatedAt,) = IChainLinkAggregator(source).latestRoundData();
        require(block.timestamp - updatedAt <= heartbeatInterval, "ORACLE_HEARTBEAT_FAILED");
        return (SafeCast.toUint256(price) * JOJOConstant.ONE) / decimalsCorrection;
    }
}
