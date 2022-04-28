//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract MyERC20 is ERC20Upgradeable {

    function initialize(string calldata name, string calldata symbol) initializer public {
        __ERC20_init(name, symbol);
    }
}