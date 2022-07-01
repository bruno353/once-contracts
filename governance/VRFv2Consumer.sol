// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./stakeable.sol";
import "./OnceToken.sol";
import "@openzeppelin/contracts/utils/Counters.sol";



contract OnceOracle is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;

  //VRF CONSUMER:

  // Your subscription ID.
  uint64 s_subscriptionId;

  // Rinkeby coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 callbackGasLimit = 1000000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 numWords =  9;

  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address s_owner;

  constructor(uint64 subscriptionId, ERC20Stakeable _token) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    tokenERC20 = _token;
    s_subscriptionId = subscriptionId;
  }

  // Assumes the subscription is funded sufficiently.
  function requestRandomWords() external onlyOwner {
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }
  uint256 public numero;
  
  function fulfillRandomWords(
    uint256 requestId, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    uint256 _tokenId = s_requestIdToTokenId[requestId];
    (,,,,,address insurer,,) = tokenERC721.Items(_tokenId);
    string memory ownerData = tokenERC721.fetchURI(insurer);
    s_randomWords = randomWords;
    _insuranceRequestsIds.increment();
    address[] memory _assessors = new address[](9);
    _assessors[0] = 0xCa7168B179f474eFb8AAE82553Eb98bD20b7b722;
    InsRequestIdToInsRequests[_insuranceRequestsIds.current()] = InsuranceRequest({
          requester: msg.sender,
          insurerData: ownerData,
          timeOfRequest: block.timestamp,
          numberOfRequests: 1,
          assessors: _assessors
        });
    numero = s_randomWords[0];
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }

  function setOwner(address _address) public onlyOwner() {
    s_owner = _address;
  }




  //ORACLE:

  using Counters for Counters.Counter;
  Counters.Counter public _insuranceRequestsIds;

  event InsuranceRequested(uint256, uint256) ;

  struct InsuranceRequest {
    address requester;
    string insurerData;
    uint256 timeOfRequest;
    uint256 numberOfRequests;
    address[] assessors;
  }
  mapping(uint256 => InsuranceRequest) InsRequestIdToInsRequests;
  mapping(uint256 => uint256) s_requestIdToTokenId;

    ERC20Stakeable public tokenERC20;
    OnceToken public tokenERC721;

    function setTokenERC20(ERC20Stakeable _token) public onlyOwner() {
        
        tokenERC20 = _token;
    }

    function setTokenERC721(OnceToken _token) public onlyOwner(){
        
        tokenERC721 = _token;
    }



    modifier NFTOwner(uint256 _tokenId){
        require(tokenERC721.ownerOf(_tokenId) == msg.sender, "Only the NFT owner can claim an insurance");
        _;
    }


    uint256 public number;


    function claimInsurance(uint256 _tokenId) public NFTOwner(_tokenId) {

        (,,,,,address insurer,,) = tokenERC721.Items(_tokenId);
        string memory ownerData = tokenERC721.fetchURI(insurer);
        _insuranceRequestsIds.increment();
        
        s_requestId = COORDINATOR.requestRandomWords(
          keyHash,
          s_subscriptionId,
          requestConfirmations,
          callbackGasLimit,
          numWords
        );

        s_requestIdToTokenId[s_requestId] = _tokenId;
        emit InsuranceRequested(s_requestId, _tokenId);

    }
    
            //InsRequestIdToInsRequests[_insuranceRequestsIds.current()] = InsuranceRequest({
          //requester: msg.sender,
         // insurerData: ownerData,
          //timeOfRequest: block.timestamp,
         // numberOfRequests: 1,
          //assessors: [0xd9145CCE52D386f254917e481eB44e9943F39138]
        //});

        //Randomly select 9 assessors for the claiming inquiry

        //address[] memory assessor;
        //for (uint i = 0; i < tokenERC20.getStakersArrLength; i++) {
            //address _assessor = tokenERC20.stakersArr(i);
            //if(tokenERC20.stakers[_assessor]){
                
            //}


}
