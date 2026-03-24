// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract RoyaltyMarketplace is ReentrancyGuard {
    
    struct Listing {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;
        bool isActive;
    }

    // Mapping from NFT Contract -> Token ID -> Listing
    mapping(address => mapping(uint256 => Listing)) public listings;

    event ItemListed(address indexed seller, address indexed nftContract, uint256 indexed tokenId, uint256 price);
    event ItemSold(address indexed buyer, address indexed nftContract, uint256 indexed tokenId, uint256 price);

    function listItems(address nftContract, uint256 tokenId, uint256 price) external {
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(nft.isApprovedForAll(msg.sender, address(this)), "Marketplace not approved");

        listings[nftContract][tokenId] = Listing(msg.sender, nftContract, tokenId, price, true);
        emit ItemListed(msg.sender, nftContract, tokenId, price);
    }

    function buyItem(address nftContract, uint256 tokenId) external payable nonReentrant {
        Listing storage listedItem = listings[nftContract][tokenId];
        require(listedItem.isActive, "Item not for sale");
        require(msg.value >= listedItem.price, "Insufficient funds");

        listedItem.isActive = false;

        uint256 royaltyAmount = 0;
        address royaltyReceiver;

        // Check for EIP-2981 Royalty Support
        if (IERC165(nftContract).supportsInterface(type(IERC2981).interfaceId)) {
            (royaltyReceiver, royaltyAmount) = IERC2981(nftContract).royaltyInfo(tokenId, msg.value);
        }

        uint256 sellerProceeds = msg.value - royaltyAmount;

        // Execute Transfers
        if (royaltyAmount > 0) {
            (bool successRoyalty, ) = payable(royaltyReceiver).call{value: royaltyAmount}("");
            require(successRoyalty, "Royalty transfer failed");
        }

        (bool successSeller, ) = payable(listedItem.seller).call{value: sellerProceeds}("");
        require(successSeller, "Seller transfer failed");

        IERC721(nftContract).safeTransferFrom(listedItem.seller, msg.sender, tokenId);

        emit ItemSold(msg.sender, nftContract, tokenId, msg.value);
    }
}
