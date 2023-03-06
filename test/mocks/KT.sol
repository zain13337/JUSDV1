// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract KT is ERC20 {
    constructor() ERC20("Mock ERC20 Type2", "MERC2") {
        _mint(msg.sender, 4000e18);
    }
}
