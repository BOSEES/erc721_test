//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract MyERC20v3 is ERC20Upgradeable {
    string public testName;
    string public testGender;

    event NameChanged(string name);
    event GenderChanged(string gender);

    function initialize(string calldata name, string calldata symbol) initializer public {
        __ERC20_init(name, symbol);
    }

    function setName(string memory _testName) public {
        testName = _testName;
        emit NameChanged(testName);
    }

    function setGender(string memory _testGender) public {
        testGender = _testGender;
        emit GenderChanged(testGender);
    }
}