// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OnceToken.sol";

contract Marketplace{
    using Counters for Counters.Counter;
    Counters.Counter public _itemsForSaleId;
    Counters.Counter public _itemsSold;

    OnceToken private token;

    constructor (OnceToken _token){
        token = _token;
    }

    uint poolFee = 0.01 ether;

    function setPoolFee(uint256 _poolFee) public{
        require(msg.sender == token.returnOwnerGovernance());
        poolFee = _poolFee;
    }


    function returnOwnerOf(uint256 _tokenId) public view returns(address){
        return token.ownerOf(_tokenId);
    }
    function returnURI(address _address) public view returns(string memory){
        return token.fetchURI(_address);
    }
      struct ItemForSale {
        uint256 tokenId;
        address payable seller;
        uint256 price;
        uint256 payout;
        bool isSold;
    }

    mapping(uint256 => ItemForSale) ItemsForSale;
    mapping(uint256 => bool) public activeItems;
    mapping(uint256 => ItemForSale) private idToMarketItem;


    event itemAddedForSale(uint256 tokenId, uint256 price, address seller, bool sold, uint256 payoutAmount);
    event itemSold(uint256 id, address buyer, uint256 price, bool sold, uint256 payoutAmount);   



    modifier IsForSale(uint256 id){
        require(!ItemsForSale[id].isSold, "Item is already sold");
        _;
    }

    modifier ItemExists(uint256 id){
        require(id < _itemsForSaleId.current() && ItemsForSale[id].tokenId == id, "Could not find item");
        _;
  }


    function putItemForSale(uint256 tokenId, uint256 price) 
        external 
        payable
        returns (uint256){
        require(!activeItems[tokenId], "Item is already up for sale");
        require(msg.value == poolFee, "msg.value must be equal to pool fee");
        require(returnOwnerOf(tokenId) == msg.sender, "You are not the token owner");

        _itemsForSaleId.increment();
        uint256 newItemsForSaleId = _itemsForSaleId.current();

        ItemsForSale[newItemsForSaleId] = ItemForSale({
            tokenId: tokenId,
            seller: payable(msg.sender),
            price: price,
            payout: token.returnItemPayout(tokenId),
            isSold: false
        });

        activeItems[tokenId] = true;

        token.safeTransferFrom(msg.sender, address(this), tokenId);
        emit itemAddedForSale(tokenId, price, msg.sender, false, token.returnItemPayout(tokenId));
        return newItemsForSaleId;
    }

    // Creates the sale of a marketplace item 
    // Transfers ownership of the item, as well as funds between parties (and gives a little of fees for the Once pool if we want)
    // I need to check if this is okay, here we give the listingPrice for our pool, as the nft was sold.
    function buyItem(uint256 id) 
        ItemExists(id)
        IsForSale(id)
        payable 
        external {
        require(msg.value >= ItemsForSale[id].price, "Not enough funds sent");
        require(msg.sender != ItemsForSale[id].seller);

        ItemsForSale[id].isSold = true;
        activeItems[ItemsForSale[id].tokenId] = false;

        token.safeTransferFrom(address(this), msg.sender, ItemsForSale[id].tokenId);
        
        payable(ItemsForSale[id].seller).transfer(msg.value - poolFee);

        _itemsSold.increment();

        emit itemSold(id, msg.sender, ItemsForSale[id].price, true, ItemsForSale[id].payout);
        }

    function totalItemsForSale() public view returns(uint256) {
        return _itemsForSaleId.current();
    }
    
    function transferNFT(uint256 _tokenId, address _address) public{
        token.safeTransferFrom(token.ownerOf(_tokenId), _address, _tokenId);
    }

    function withdrawToken() public {
        require(msg.sender == token.returnOwnerGovernance(), "Only the ownerGovernance can withdraw the tokens.");
        bool sent = payable(msg.sender).send(address(this).balance);
        require(sent, "Failed to send Ether"); 
        }
}
