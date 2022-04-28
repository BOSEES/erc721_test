//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyERC721v3 is ERC721Upgradeable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string public testName;
    string public testGender;

    event NameChanged(string name);
    event GenderChanged(string gender);

    function initialize(string calldata name, string calldata symbol) initializer public {
        __ERC721_init(name, symbol);
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