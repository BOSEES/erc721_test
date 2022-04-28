//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract MyERC20v2 is ERC20Upgradeable {
    string public testName;
    
    event NameChanged(string name);

    function initialize(string calldata name, string calldata symbol) initializer public {
        __ERC20_init(name, symbol);
    }

    function setName(string memory _testName) public {
        testName = _testName;
        emit NameChanged(testName);
    }
}