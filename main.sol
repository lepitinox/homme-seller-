pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract HouseHistoryNFT is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    struct HouseHistory {
        uint256 constructionDate;
        address[] previousOwners;
        string[] repairs;
        string[] renovations;
    }

    mapping(uint256 => HouseHistory) public houseHistories;

    constructor() ERC721("HouseHistoryNFT", "HHNFT") {}

    function mintHouseHistoryNFT(
        address to,
        uint256 constructionDate,
        string memory repairs,
        string memory renovations,
        string memory uri
    ) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        HouseHistory memory newHouseHistory = HouseHistory({
            constructionDate: constructionDate,
            previousOwners: new address[](0),
            repairs: new string[](0),
            renovations: new string[](0)
        });
        # TODO : Fix this
        newHouseHistory.repairs.push(repairs);
        newHouseHistory.renovations.push(renovations);
        houseHistories[tokenId] = newHouseHistory;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        super.transferFrom(from, to, tokenId);
        houseHistories[tokenId].previousOwners.push(to);
    }

    function addRepair(uint256 tokenId, string memory repair) public onlyOwner {
        houseHistories[tokenId].repairs.push(repair);
    }

    function addRenovation(uint256 tokenId, string memory renovation) public onlyOwner {
        houseHistories[tokenId].renovations.push(renovation);
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