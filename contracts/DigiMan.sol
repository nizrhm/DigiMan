// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract DigiMan is ERC721URIStorage {
    address payable public marketplaceOwner;
    uint256 public listingFeePercent = 20;
    uint256 private currentTokenId;
    uint256 private totalItemsSold;

    struct AssetListing {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
    }

    mapping (uint256 => AssetListing) private tokenIdToListing;

    modifier onlyOwner {
        require(msg.sender == marketplaceOwner, "Only owner can call this function");
        _;
    }

    constructor() ERC721("DigiMan", "AssetS"){
        marketplaceOwner = payable(msg.sender);
    }

    function updateListingFeePercent(uint256 _listingFeePercent) public onlyOwner{
        listingFeePercent = _listingFeePercent;
    }

    function getListingFeePercent() public view returns (uint256) {
        return listingFeePercent;
    }

    function getCurrentTokenId() public view returns(uint256) {
        return currentTokenId;
    }

    function getAssetListing(uint256 _tokenId) public view returns(AssetListing memory){
        return tokenIdToListing[_tokenId];
    }

    function createToken(string memory _tokenURI, uint256 _price) public returns(uint256){
        require(_price > 0, "Price must be greater than zero");

        currentTokenId++;
        uint256 newTokenId = currentTokenId;
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);

        _createAssetListing(newTokenId, _price);

        return newTokenId;
    }

    function _createAssetListing(uint256 _tokenId, uint256 _price) private{
        tokenIdToListing[_tokenId] = AssetListing({
            tokenId: _tokenId,
            owner: payable(msg.sender),
            seller: payable(msg.sender),
            price: _price
        });
    }

    function executeSale(uint256 tokenId) public payable{
        AssetListing storage listing = tokenIdToListing[tokenId];
        uint256 price = listing.price;
        address payable seller = listing.seller;

        require(msg.value == price, "Please submit the asking price to complete the purchase");

        listing.seller = payable(msg.sender);
        totalItemsSold++;

        _transfer(listing.owner, msg.sender, tokenId);

        uint256 listingFee = (price * listingFeePercent) / 100;
        marketplaceOwner.transfer(listingFee);
        seller.transfer(msg.value - listingFee);
    }

    function getAllListedAssets() public view returns (AssetListing[] memory){
        uint256 totalAssetCount = currentTokenId;
        AssetListing[] memory listedAssets = new AssetListing[](totalAssetCount);
        uint256 currentIndex = 0;

        for(uint256 i = 0; i < totalAssetCount; i++){
            uint256 tokenId = i + 1;
            AssetListing storage listing = tokenIdToListing[tokenId];
            listedAssets[currentIndex] = listing;
            currentIndex += 1;
        }

        return listedAssets;
    }

    function getMyAssets() public view returns(AssetListing[] memory) {
        uint256 totalAssetCount = currentTokenId;
        uint256 myAssetCount = 0;
        uint256 currentIndex = 0;

        for(uint256 i = 0; i < totalAssetCount; i++){
            if(tokenIdToListing[i+1].owner == msg.sender || tokenIdToListing[i+1].seller == msg.sender){
                myAssetCount++;
            }
        }

        AssetListing[] memory myAssets = new AssetListing[](myAssetCount);
        for(uint256 i = 0; i < totalAssetCount; i++){
            if(tokenIdToListing[i+1].owner == msg.sender || tokenIdToListing[i+1].seller == msg.sender){
                uint256 tokenId = i + 1;
                AssetListing storage listing = tokenIdToListing[tokenId];
                myAssets[currentIndex] = listing;
                currentIndex++;
            }
        }

        return myAssets;
    }
}