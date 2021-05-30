// SPDX-License-Identifier: MIT

// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721

pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract SaturnaNFT is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;
    Counters.Counter public _NFTTypeIds;
    
    IERC20 public saturna;
    // Mapping NFT Type ID to its URI and count
    mapping (uint256 => NFT) public NFTTypeMap;
    mapping (address => mapping (uint256 => uint256[])) public NFTAddressToID;

    mapping (address => bool) public isWhitelisted;

    address public devAddress;

    constructor(address _saturnaAddress, address _devAddress) 
    
    public ERC721("SATURNA", "SAT") {
        isWhitelisted[msg.sender] = true;
        saturna = IERC20(_saturnaAddress);
        devAddress = _devAddress;
    }

    struct NFT {
        uint256 typeId;
        uint256 count;
        uint256 minted;
        string tokenURI;
        uint256 price;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 saturnaAmount;
    }

    modifier onlyWhitelist() {
        require(isWhitelisted[_msgSender()], "Whitelist: Address not whitelisted");
        _;
    }

    receive() external payable {}

    function addWhitelist(address _whitelistAddress) external onlyOwner {
        isWhitelisted[_whitelistAddress] = true;
    }

    function removeWhitelist(address _whitelistAddress) external onlyOwner {
        require(isWhitelisted[_whitelistAddress], "User does not exist");
        isWhitelisted[_whitelistAddress] = false;
    }


    function addNFT(uint256 _count, string memory _tokenURI, uint256 _price,
    uint256 _startTimestamp, uint256 _endTimestamp, uint256 _saturnaAmount) 
    external onlyWhitelist returns (uint256) {
        
        uint256 typeId = _NFTTypeIds.current();

        NFTTypeMap[typeId] = NFT(typeId, _count, 0, _tokenURI, _price, 
        _startTimestamp, _endTimestamp, _saturnaAmount);

        _NFTTypeIds.increment();
        return typeId;
    } 

    function buyNFT(uint256 typeId) external payable returns (uint256) {
        _tokenIds.increment();

        address recipient = msg.sender;
        NFT memory nft = NFTTypeMap[typeId];

        // Make sure buyer is paying right price
        require(msg.value == nft.price, "Price is incorrect");
        // Make sure there are NFTs still available
        require(nft.count > 0, "NFTs are not available");
        require(nft.startTimestamp <= block.timestamp, "Too early to get NFT");
        require(nft.endTimestamp >= block.timestamp, "Too late to get NFT");
        // Make sure buyer holds correct amount of saturna
        require(saturna.balanceOf(msg.sender) >= nft.saturnaAmount, 
        "Need to hold correct amount of saturna in wallet");

        // Remove NFT from minting
        uint256 count = NFTTypeMap[typeId].count;
        uint256 minted = NFTTypeMap[typeId].minted;
        NFTTypeMap[typeId].count = count.sub(1);
        NFTTypeMap[typeId].minted = minted.add(1);
        uint256 newItemId = _tokenIds.current();
        NFTAddressToID[recipient][typeId].push(newItemId);
        // Changed this to be safeMint from Mint
        _safeMint(recipient, newItemId);
        _setTokenURI(newItemId, nft.tokenURI);

        uint256 devAmount = (msg.value).mul(10).div(100);
        payable(devAddress).transfer(devAmount);

        return newItemId;
    }

    function setSaturnaAddress (address _saturnaAddress) external onlyOwner {
        saturna = IERC20(_saturnaAddress); 
    }

    function setNFTMint (uint256 typeId, uint256 _minted) external onlyWhitelist {
        NFTTypeMap[typeId].minted = _minted;
    }

    function setNFTCount (uint256 typeId, uint256 _count) external onlyWhitelist {
        NFTTypeMap[typeId].count = _count;
    }

    function setNFTSaturnaAmount (uint256 typeId, uint256 _saturnaAmount) 
    external onlyWhitelist {
        NFTTypeMap[typeId].saturnaAmount = _saturnaAmount;
    }

    function setNFTStartTimestamp (uint256 typeId, uint256 _startTimestamp) 
    external onlyWhitelist {
        NFTTypeMap[typeId].startTimestamp = _startTimestamp;
    }

    function setNFTEndTimestamp (uint256 typeId, uint256 _endTimestamp) 
    external onlyWhitelist {
        NFTTypeMap[typeId].endTimestamp = _endTimestamp;
    }

    function setNFTTokenURI (uint256 typeId, string memory _tokenURI) 
        external onlyWhitelist {
        NFTTypeMap[typeId].tokenURI = _tokenURI;
    }

    function setNFTPrice (uint256 typeId, uint256 _price) external onlyWhitelist {
        NFTTypeMap[typeId].price = _price;
    }

    function getNFTCount (uint256 typeId) external view returns (uint256) {
        return NFTTypeMap[typeId].count; 
    }

    function getNFTPrice (uint256 typeId) external view returns (uint256) {
        return NFTTypeMap[typeId].price;
    }

    function getNFTMint (uint256 typeId) external view returns (uint256) {
        return NFTTypeMap[typeId].minted;
    }

    function getNFTTokenURI (uint256 typeId) external view returns 
        (string memory) {
        return NFTTypeMap[typeId].tokenURI;
    }

    function isNFTAvailable (uint256 typeId) external view returns (bool) {
        return NFTTypeMap[typeId].count > 0;
    }

    function getIDFromMap (address wallet, uint256 packId) external view returns (uint256[] memory) {
        return NFTAddressToID[wallet][packId];
    }

    function withdrawFunds(address _payeeWallet) external onlyOwner returns (bool) {
        require(address(this).balance > 0);
        payable(_payeeWallet).transfer(address(this).balance);
        return true;
    }

    function setDevAddress (address _devAddress) external onlyOwner {
        devAddress = _devAddress;
    }
}
