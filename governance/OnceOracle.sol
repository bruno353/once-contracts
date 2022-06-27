// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./stakeable.sol";
import "./OnceToken.sol";
import "./VRFv2Consumer.sol";


contract Oracle is ReentrancyGuard {

    ERC20Stakeable public tokenERC20;
    OnceToken public tokenERC721;
    VRFv2Consumer public randomNumberContract;

    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
  }

    constructor (ERC20Stakeable _token){
        owner = msg.sender;
        tokenERC20 = _token;
    }

    function setTokenERC20(ERC20Stakeable _token) public onlyOwner() {
        
        tokenERC20 = _token;
    }

    function setTokenERC721(OnceToken _token) public onlyOwner(){
        
        tokenERC721 = _token;
    }

    function setRandomNumberContract(VRFv2Consumer _token) public onlyOwner() {
        
        randomNumberContract = _token;
    }


    function setOwner(address _address) public onlyOwner() {
        
        owner = _address;
    }

    modifier NFTOwner(uint256 _tokenId){
        require(tokenERC721.ownerOf(_tokenId) == msg.sender, "Only the NFT owner can claim an insurance");
        _;
    }
    uint256 public number;

    function claimInsurance() public {
        //(,,,,,address insurer,,) = tokenERC721.Items(_tokenId);
        //string memory ownerData = tokenERC721.fetchURI(insurer);
        randomNumberContract.requestRandomWords();
        number = randomNumberContract.s_randomWords(0);
    }
    
    //function claimInsurance(uint256 _tokenId) NFTOwner(_tokenId) public {
        //(,,,,,address insurer,,) = tokenERC721.Items(_tokenId);
        //string memory ownerData = tokenERC721.fetchURI(insurer);
        //randomNumberContract.requestRandomWords();
        //number = randomNumberContract.s_randomWords(0);
    //}
    

}
