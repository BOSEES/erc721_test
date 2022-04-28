//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./MerkleProof.sol";
import "./MinterRole.sol";

contract MyERC721 is ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable, MinterRole {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint256;
    CountersUpgradeable.Counter private _tokenIds;

    mapping (address => uint256) private _lastCallBlockNumber;
    uint256 private _antibotInterval;

    uint256 private _mintIndexForSale;

    uint256 private _mintLimitPerBlock;
    uint256 private _mintLimitPerSale;

    string private _tokenBaseURI;
    uint256 private _mintStartBlockNumber;
    uint256 private _maxSaleAmount;
    uint256 private _mintPrice;

    string baseURI;
    string notRevealedURI;
    bool public revealed;
    bool public publicMintEnabled;

    bytes32 public merkleRoot;
    bool public whitelistMintEnabled;
    mapping(address => bool) public whitelistClaimed;

    function initialize(string calldata name, string calldata symbol) initializer public {
        __ERC721_init(name, symbol);
        __ERC721URIStorage_init();
        _addMinter(msg.sender);
        _mintIndexForSale = 1;
        revealed = false;
        publicMintEnabled = false;
        whitelistMintEnabled = false;
    }

    function publicMint(uint256 requestedCount) external payable {
        require(publicMintEnabled, "The public sale is not enabled!");
        require(_lastCallBlockNumber[msg.sender].add(_antibotInterval) < block.number, "Bot is not allowed");
        require(block.number >= _mintStartBlockNumber, "Not yet started");
        require(requestedCount > 0 && requestedCount <= _mintLimitPerBlock, "Too many requests or zero request");
        require(msg.value == _mintPrice.mul(requestedCount), "Not enough Coin");
        require(_mintIndexForSale.add(requestedCount) <= _maxSaleAmount + 1, "Exceed max amount");
        require(balanceOf(msg.sender) + requestedCount <= _mintLimitPerSale, "Exceed max amount per person");

        for(uint256 i = 0; i < requestedCount; i++) {
            _mint(msg.sender, _mintIndexForSale);
            _mintIndexForSale = _mintIndexForSale.add(1);
        }
        _lastCallBlockNumber[msg.sender] = block.number;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        require(_exists(tokenId),"KIP17Metadata: URI query for nonexistent token");

        if(revealed == false) {
            string memory currentNotRevealedURI = _notRevealedURI();
            return bytes(currentNotRevealedURI).length > 0
                ? string(abi.encodePacked(currentNotRevealedURI, StringsUpgradeable.toString(tokenId), ".json"))
                : "";
        }
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, StringsUpgradeable.toString(tokenId), ".json"))
            : "";
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal view override(ERC721Upgradeable) returns (string memory) {
        return baseURI;
    }

    function _notRevealedURI() internal view returns (string memory) {
        return notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _newNotRevealedURI) public onlyOwner {
        notRevealedURI = _newNotRevealedURI;
    }

    function reveal(bool _state) public onlyOwner {
        revealed = _state;
    }

    function mintingInformation() external view returns (uint256[7] memory){
        uint256[7] memory info =
        [_antibotInterval, _mintIndexForSale, _mintLimitPerBlock, _mintLimitPerSale, 
            _mintStartBlockNumber, _maxSaleAmount, _mintPrice];
        return info;
    }

    function setPublicMintEnabled(bool _state) public onlyMinter {
        publicMintEnabled = _state;
    }

    function setupSale(uint256 newAntibotInterval, 
                        uint256 newMintLimitPerBlock,
                        uint256 newMintLimitPerSale,
                        uint256 newMintStartBlockNumber,
                        uint256 newMintIndexForSale,
                        uint256 newMaxSaleAmount,
                        uint256 newMintPrice) external onlyMinter{
        _antibotInterval = newAntibotInterval;
        _mintLimitPerBlock = newMintLimitPerBlock;
        _mintLimitPerSale = newMintLimitPerSale;
        _mintStartBlockNumber = newMintStartBlockNumber;
        _mintIndexForSale = newMintIndexForSale;
        _maxSaleAmount = newMaxSaleAmount;
        _mintPrice = newMintPrice;
    }
    
    //Whitelist Mint
    function setMerkleRoot(bytes32 _merkleRoot) public onlyMinter {
        merkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyMinter initializer {
        whitelistMintEnabled = _state;
    }

    function whitelistMint(uint256 requestedCount, bytes32[] calldata _merkleProof) external payable {
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        require(msg.value == _mintPrice.mul(requestedCount), "Not enough Coin");
        require(!whitelistClaimed[msg.sender], 'Address already claimed!');
        require(requestedCount > 0 && requestedCount <= _mintLimitPerBlock, "Too many requests or zero request");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

        for(uint256 i = 0; i < requestedCount; i++) {
            _mint(msg.sender, _mintIndexForSale);
            _mintIndexForSale = _mintIndexForSale.add(1);
        }

        whitelistClaimed[msg.sender] = true;
    }

    //Airdrop Mint
    function airDropMint(address user, uint256 requestedCount) external onlyMinter {
        require(requestedCount > 0, "zero request");
        for(uint256 i = 0; i < requestedCount; i++) {
            _mint(user, _mintIndexForSale);
            _mintIndexForSale = _mintIndexForSale.add(1);
        }
    }
}