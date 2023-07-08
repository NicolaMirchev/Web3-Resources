// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract MoodNft is ERC721 {
    error MoodNft__CantFlipMoonIfNotOwner();

    uint256 private s_tokenCounter;
    string private s_sadSvgImageUri;
    string private s_happySvgImageUri;

    enum Mood{
        HAPPY,
        SAD
    }

    mapping(uint256 => Mood) private s_tokenIdToMood;

    constructor(string memory sadSvg, string memory happySvg)ERC721("Mood NFT", "MN"){
        s_sadSvgImageUri = sadSvg;
        s_happySvgImageUri = happySvg;
        s_tokenCounter = 0;
    }

    function mintNft( ) public {
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenIdToMood[s_tokenCounter] = Mood.HAPPY;
        s_tokenCounter++;
    }

    function flipMood(uint256 tokenId) public{
        if(!_isApprovedOrOwner(msg.sender, tokenId)){
            revert MoodNft__CantFlipMoonIfNotOwner();
        }

        if (s_tokenIdToMood[tokenId] == Mood.HAPPY) {
            s_tokenIdToMood[tokenId] = Mood.SAD;
        } else {
            s_tokenIdToMood[tokenId] = Mood.HAPPY;
        }
    }

    function tokenURI(uint256 tokenId) public view override returns(string memory){
        string memory imageURI;
        if(s_tokenIdToMood[tokenId] == Mood.HAPPY){
            imageURI = s_happySvgImageUri;
        }
        else{
            imageURI = s_sadSvgImageUri; 
        }
        return
        string(
        abi.encodePacked(_baseURI(),
        Base64.encode(
        bytes(abi.encodePacked(string.concat('{"name": "', name(),
        '", "description" : "An NFT that reflects the owners mood." , "attributes": [{"trait_type": "moodiness", "value" : 100}], "image": "' 
        ,imageURI,'"}'))))));
    }

    function _baseURI() internal pure override returns (string memory){
        return "data:application/json;base64,";
    }
}