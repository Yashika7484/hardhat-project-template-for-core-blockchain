// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title DynamicNFTMarketplace
 * @dev A marketplace for dynamic NFTs that can evolve over time
 */
contract DynamicNFTMarketplace is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    // Mapping from token ID to token price
    mapping(uint256 => uint256) public tokenPrices;
    
    // Mapping from token ID to token evolution stage
    mapping(uint256 => uint256) public tokenEvolutionStages;
    
    // Mapping from token ID to metadata URI for each evolution stage
    mapping(uint256 => mapping(uint256 => string)) public evolutionStageURIs;
    
    // Events
    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTPurchased(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);
    event NFTEvolved(uint256 indexed tokenId, uint256 newStage);
    
    constructor() ERC721("DynamicNFT", "DNFT") Ownable(msg.sender) {}
    
    /**
     * @dev Creates a new NFT with initial evolution stage and lists it for sale
     * @param initialURI The initial metadata URI for the NFT
     * @param price The listing price in wei
     * @return The ID of the newly created NFT
     */
    function createAndListNFT(string memory initialURI, uint256 price) external returns (uint256) {
        require(price > 0, "Price must be greater than zero");
        
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, initialURI);
        
        // Set initial evolution stage
        tokenEvolutionStages[newTokenId] = 1;
        evolutionStageURIs[newTokenId][1] = initialURI;
        
        // List the NFT for sale
        tokenPrices[newTokenId] = price;
        
        emit NFTListed(newTokenId, msg.sender, price);
        
        return newTokenId;
    }
    
    /**
     * @dev Allows users to purchase an NFT
     * @param tokenId The ID of the NFT to purchase
     */
    function purchaseNFT(uint256 tokenId) external payable {
        address seller = ownerOf(tokenId);
        require(seller != msg.sender, "Cannot buy your own NFT");
        require(tokenPrices[tokenId] > 0, "NFT not for sale");
        require(msg.value >= tokenPrices[tokenId], "Insufficient funds");
        
        // Transfer ownership
        _transfer(seller, msg.sender, tokenId);
        
        // Transfer funds to seller
        payable(seller).transfer(msg.value);
        
        // Remove listing
        delete tokenPrices[tokenId];
        
        emit NFTPurchased(tokenId, seller, msg.sender, msg.value);
    }
    
    /**
     * @dev Evolves an NFT to the next stage
     * @param tokenId The ID of the NFT to evolve
     * @param newStageURI The metadata URI for the new evolution stage
     */
    function evolveNFT(uint256 tokenId, string memory newStageURI) external {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        
        uint256 currentStage = tokenEvolutionStages[tokenId];
        uint256 newStage = currentStage + 1;
        
        // Update evolution stage
        tokenEvolutionStages[tokenId] = newStage;
        evolutionStageURIs[tokenId][newStage] = newStageURI;
        
        // Update token URI
        _setTokenURI(tokenId, newStageURI);
        
        emit NFTEvolved(tokenId, newStage);
    }
    
    /**
     * @dev Updates the price of an NFT listing
     * @param tokenId The ID of the NFT
     * @param newPrice The new price in wei
     */
    function updateListingPrice(uint256 tokenId, uint256 newPrice) external {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        require(newPrice > 0, "Price must be greater than zero");
        
        tokenPrices[tokenId] = newPrice;
        
        emit NFTListed(tokenId, msg.sender, newPrice);
    }
    
    /**
     * @dev Gets the current evolution stage of an NFT
     * @param tokenId The ID of the NFT
     * @return The current evolution stage
     */
    function getCurrentEvolutionStage(uint256 tokenId) external view returns (uint256) {
        require(_ownerOf(tokenId) != address(0), "NFT does not exist");
        return tokenEvolutionStages[tokenId];
    }
}
