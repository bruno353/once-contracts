// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract OnceToken is ERC721Enumerable{
  using Counters for Counters.Counter;
  
  Counters.Counter public _tokenIds;
  Counters.Counter public _insuredIds;

  address public marketplace;

  //For minting NFTs, you we need the ANIMA tokens
  IERC20 public tokenAddress;

  //ANIMA tokens required for minting an NFT 
  uint256 public rate = 100 * 10 ** 18;
  
  //setting a governance oracle/DAO that will grants access for minting Once NFTs
  //So who pass the Once KYC system will have the permission for minting:
  address public ownerGovernance = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4; 

  uint256 poolFee = 0.01 ether;


  constructor () ERC721("OnceToken", "ONCE") {}



  //Creating the insured structs:
  struct Insured {
    address insured;
    string uri;
  }

  event insuredGranted(address insured);

  mapping(uint256 => Insured) public Insureds;
  mapping(address => string) public AddressToURI;

  //So here, with the the governance address, we grant for the user the possibility to mint Once NFTs (after checking the KYC):
  function grantInsuranceMint(address _address, string memory _uri) public returns(uint256){
    require(msg.sender == ownerGovernance, "Only the DAO governance can set this role");
    require(exists1(_address) == false, "This address already is granted");
    _insuredIds.increment();
    uint256 newInsuredId = _insuredIds.current();
    Insureds[newInsuredId] = Insured ({
      insured: _address,
      uri: _uri
    });
    AddressToURI[_address] = _uri;

    emit insuredGranted(Insureds[newInsuredId].insured);
    return newInsuredId;
  }

  //remove grant to insured:
  function removeGrantToInsured(uint256 num) public{
    require(msg.sender == ownerGovernance, "Only the DAO governance can do it");
    delete Insureds[num];
  }

  //return Insured address by Id:
  function fetchInsured(uint256 num) public view returns(address){
    return Insureds[num].insured;
  }

  //function for checking if address is granted for minting
  function exists1(address _address) internal view returns (bool) {
    uint count = _insuredIds.current();
    for (uint i = 0; i < count + 1; i++) {
        if (Insureds[i].insured == _address) {
            return true;
        }
    }

    return false;
  }

  //Creating the nfts struct:
  struct Item {
    address creator;
    string uri;//metadata url
    //premium for insurance
    uint256 premium;
    //boolean for knowing if the nft was backed or not:
    bool backed;
    //the amount of money the insured wants to be backed for his premium, in case of death who owns the nfts can claim the reward:
    uint256 payout;
    //who backs this nft will be the insurer
    address insurer;
    //if the assurance was triggered, it has to wait the claiming process to do anything (transfers, cliamings, selling to marketplace etc)
    bool assuranceTriggered;
    //if the assurance was already called, if so this nft does not own more value:
    bool assuranceClaimed;
  }

  event NFTMinted (address creator, string uri, uint256 premium, bool backed, uint256 payout);

  mapping(uint256 => Item) public Items; //id => Item

  

  //when minting the user pass the uri, the premium (its the msg.value) and the amount the wants in case of dead (payout)
  function mint(string memory uri, uint256 _payout) public payable returns (uint256){
    require(exists1(msg.sender) == true, "You are not an allowed insured");
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();
    _safeMint(msg.sender, newItemId);
    approve(marketplace, newItemId);

    Items[newItemId] = Item({
      creator: msg.sender,
      uri: uri,
      premium: msg.value,
      backed: false,
      payout: _payout,
      insurer: msg.sender,
      assuranceTriggered: false,
      assuranceClaimed: false
    });

    emit NFTMinted(Items[newItemId].creator, Items[newItemId].uri, Items[newItemId].premium, Items[newItemId].backed, Items[newItemId].payout);
    return newItemId;
  }


  function setMarketplace(address market) public {
    require(msg.sender == ownerGovernance, "Only the DAO governance can set the marketplace");
    marketplace = market;
  }

  function setTokenAddress(address _address) public {
      require(msg.sender == ownerGovernance, "Only the DAO governance can set the tokenAddress");
      tokenAddress =  IERC20(_address);
  }

  function setANIMAFee(uint256 _fee) public{
      require(msg.sender == ownerGovernance, "Only the DAO governance can set the ANIMA fee");
      rate = _fee;
  }

  function setPoolFee(uint256 _poolFee) public {
      require(msg.sender == ownerGovernance, "Only the ownerGovernance can set the pool's fee!!" );
      poolFee = _poolFee;
  }

  function fetchTokensIds() public view returns(uint256){
      return _tokenIds.current();
  }




  //getPayout is triggered when the insured dies - who owns the nft will get the payout:
  function getPayout(uint256 _tokenId) public {
    require(msg.sender == ownerGovernance, "Only the ownerGovernance can withdraw!!");
    require(Items[_tokenId].assuranceTriggered == false, "This assurance was already called");

    address payable _to = payable(ownerOf(_tokenId));

    uint256 payout = Items[_tokenId].payout - poolFee;
    
    Items[_tokenId].assuranceTriggered = true;

    //transfer the payout amount to the NFT owner:
    (bool sent, ) = payable(_to).call{value: payout}("");
    require(sent, "Failed to send Ether/Matic");
  }

  //getAmountBack is triggered when the timestamp in the insurance contract has passed and the insured has not died, the money goes back to the insurer:
  function getAmountBack(uint256 _tokenId) public {
    require(msg.sender == ownerGovernance, "Only the ownerGovernance can withdraw!!");  
    require(Items[_tokenId].assuranceTriggered == false, "This assurance was already called");

    address payable _to = payable(Items[_tokenId].insurer);

    uint256 payout = Items[_tokenId].payout - poolFee;

    Items[_tokenId].assuranceTriggered = true;

    //transfer the payout amount to the insurer:
    (bool sent, ) = payable(_to).call{value: payout}("");
    require(sent, "Failed to send Ether/Matic");
  }

  function fetchURI(address _address) public view returns(string memory){
      return AddressToURI[_address];
  }

  function returnItem(uint256 _tokenId) public view returns(Item memory){
      return Items[_tokenId];
  }
  function returnItemPayout(uint256 _tokenId) public view returns(uint256){
      return Items[_tokenId].payout;
  }
  function returnOwnerGovernance() public view returns(address){
      return ownerGovernance;
  }
}
