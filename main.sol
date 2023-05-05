// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts@4.8.3/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.8.3/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.8.3/access/Ownable.sol";
import "@openzeppelin/contracts@4.8.3/utils/Counters.sol";

contract MyToken is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    struct HouseHistory {
        uint256 constructionDate;
        address[] previousOwners;
    }
    struct HouseSale {
        bool isForSale;
        uint256 price;
    }

    mapping(uint256 => HouseHistory) public houseHistories;
    mapping(uint256 => HouseSale) public houseSales;

    event HouseMinted(uint256 tokenId, address owner);
    event HouseSaleUpdated(uint256 tokenId, bool isForSale, uint256 price);
    event HouseSold(uint256 tokenId, address seller, address buyer, uint256 price);

    constructor() ERC721("HouseHistoryNFT", "HHNFT") {}
    
    function safeMint(
        address to,
        uint256 constructionDate,
        string memory uri
    ) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

         HouseHistory memory newHouseHistory = HouseHistory({
              constructionDate: constructionDate,
              previousOwners: new address[](0)
    });
    houseHistories[tokenId] = newHouseHistory;
    emit HouseMinted(tokenId, to);
    }

    function putHouseForSale(uint256 tokenId, uint256 price) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        houseSales[tokenId] = HouseSale({isForSale: true, price: price});
        emit HouseSaleUpdated(tokenId, true, price);
    }

    function cancelHouseSale(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        houseSales[tokenId].isForSale = false;
        emit HouseSaleUpdated(tokenId, false, 0);
    }

    function buyHouse(uint256 tokenId) public payable {
        HouseSale memory houseSale = houseSales[tokenId];
        require(houseSale.isForSale, "House is not for sale");
        require(msg.value >= houseSale.price, "Insufficient funds");

        address seller = ownerOf(tokenId);
        _transfer(seller, msg.sender, tokenId);
        houseHistories[tokenId].previousOwners.push(msg.sender);
        houseSales[tokenId].isForSale = false;

        payable(seller).transfer(houseSale.price);

        emit HouseSold(tokenId, seller, msg.sender, houseSale.price);
    }
    function getHousesForSale() public view returns (uint256[] memory) {
        uint256 totalHouses = _tokenIdCounter.current();



        // Count the number of houses for sale
        uint256 housesForSaleCount = 0;
        for (uint256 i = 1; i <= totalHouses; i++) {
            if (houseSales[i].isForSale) {
                housesForSaleCount++;
            }
        }

        // Create an array with the tokenIds of the houses for sale
        uint256[] memory housesForSale = new uint256[](housesForSaleCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= totalHouses; i++) {
            if (houseSales[i].isForSale) {
                housesForSale[index] = i;
                index++;
            }
        }

        return housesForSale;
    }

    function getHouseState(uint256 tokenId) public view returns (bool isForSale, uint256 price) {
        require(_exists(tokenId), "House does not exist");
        HouseSale memory houseSale = houseSales[tokenId];
        return (houseSale.isForSale, houseSale.price);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        super.transferFrom(from, to, tokenId);
        houseHistories[tokenId].previousOwners.push(to);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
