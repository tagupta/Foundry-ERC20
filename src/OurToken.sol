// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract OurToken is ERC20 {
    string public constant TOKEN_NAME = "OurToken";
    string public constant TOKEN_SYMBOL = "OTK";

    constructor(uint256 initalSupply) ERC20(TOKEN_NAME, TOKEN_SYMBOL) {
        _mint(msg.sender, initalSupply);
    }
}
