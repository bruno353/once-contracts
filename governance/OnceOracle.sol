// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./stakeable.sol";
import "./OnceToken.sol";

//THIS IS THE TIME TOKEN -> STAKEABLE TOKEN.

contract Oracle is ReentrancyGuard {

    ERC20Stakeable public tokenERC20;
    OnceToken public tokenERC721;
    address owner;

    constructor (ERC20Stakeable _token){
        owner = msg.sender;
        tokenERC20 = _token;
    }

    function setTokenERC20(ERC20Stakeable _token) public {
        require(owner == msg.sender);
        tokenERC20 = _token;
    }

    function setTokenERC721(OnceToken _token) public {
        require(owner == msg.sender);
        tokenERC721 = _token;
    }


    function setOwner(address _address) public {
        require(owner == msg.sender);
        owner = _address;
    }

    

}
