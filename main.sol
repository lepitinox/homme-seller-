// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract HomeSeller is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    struct Vente {
        address seller;
        uint256 tokenId;
        uint256 price;
        bool isActive;
    }

    mapping (uint256 => Vente) public houseSales;
    event VenteCree(address indexed seller, uint256 indexed tokenId, uint256 price);
    event VenteAnnule(address indexed seller, uint256 indexed tokenId);
    event VenteTermine(address indexed seller, address indexed buyer, uint256 indexed tokenId, uint256 price);

    constructor() ERC721("HouseHistoryNFT", "HHNFT") {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmNfzQQMirgdLaanLV7XkwAr7SXzC8V13kqsYeyDon8Lsu";
    }

    function safeMint(address to) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(_baseURI(), tokenId)));
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function createVente(uint256 tokenId, uint256 price) external payable {
        require(_isApprovedOrOwner(msg.sender,tokenId), "You must own the token to sell it");
        if(houseSales[tokenId].price != 0){
            houseSales[tokenId].isActive = true;
        }
        else{
            houseSales[tokenId] = Vente(msg.sender, tokenId, price, true);
        }
        emit VenteCree(msg.sender, tokenId, price);
        
    }

    function acheter(uint256 tokenId) external payable {
        require(houseSales[tokenId].isActive, "La vente est inactive");
        require(msg.value >= houseSales[tokenId].price, "Fond insuffisant");
        address payable seller = payable(houseSales[tokenId].seller);
        address buyer = msg.sender;
        uint256 price = houseSales[tokenId].price;
        _transfer(seller,buyer,tokenId);
        houseSales[tokenId].isActive = false;
        seller.transfer(msg.value);
        emit VenteTermine(seller, buyer, tokenId, price);
    }

    function annulerVente(uint256 tokenId) external {
        require(houseSales[tokenId].seller == msg.sender, "Vous n tes pas le proprietaire de cette vente");
        houseSales[tokenId].isActive = false;
        emit VenteAnnule(msg.sender, tokenId);
    }

    function getHousesForSale() public view returns (uint256[] memory) {
        uint256 totalHouses = _tokenIdCounter.current();

        // Count the number of houses for sale
        uint256 housesForSaleCount = 0;
        for (uint256 i = 1; i <= totalHouses; i++) {
            if (houseSales[i].isActive) {
                housesForSaleCount++;
            }
        }

        // Create an array with the tokenIds of the houses for sale
        uint256[] memory housesForSale = new uint256[](housesForSaleCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= totalHouses; i++) {
            if (houseSales[i].isActive) {
                housesForSale[index] = i;
                index++;
            }
        }

        return housesForSale;
    }

    function getHouseState(uint256 tokenId) public view returns (bool isForSale, uint256 price) {
        require(_exists(tokenId), "House does not exist");
        Vente memory houseSale = houseSales[tokenId];
        return (houseSale.isActive, houseSale.price);
    }

}