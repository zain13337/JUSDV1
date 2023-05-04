/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1
*/

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@JOJO/contracts/adaptor/emergencyOracle.sol";

/// @notice emergency fallback oracle.
/// Using when the third party oracle is not available.
contract EmergencyOracleFeed is Ownable{
    uint256 public price;
    uint256 public roundId;
    string public description;
    bool public turnOn;
    address public priceFeedOracle;

    // Align with chainlink
    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 updatedAt
    );

    constructor(address _owner, string memory _description, address _priceFeed) Ownable() {
        transferOwnership(_owner);
        description = _description;
        priceFeedOracle = _priceFeed;
    }

    function getAssetPrice() external view returns (uint256) {
        require(turnOn, "the emergency oracle is close");
        return EmergencyOracle(priceFeedOracle).getMarkPrice();
    }

    function turnOnOracle() external onlyOwner {
        turnOn = true;
    }

    function turnOffOracle() external onlyOwner {
        turnOn = false;
    }

}
