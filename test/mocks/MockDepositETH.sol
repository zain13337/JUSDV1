pragma solidity ^0.8.0;

contract MockDepositETH {
    uint256 balance;

    event Received(address sender, uint256 value);

    function deposit() public payable{
        balance += msg.value;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    fallback() external payable {
    }


}
