// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BasicNft is ERC721 {
    // token id will never gonna change so make it "CONSTANT"
    string public constant TOKEN_URI =
        "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";

    uint256 private s_tokenCounter;

    constructor() ERC721("Dogie", "DOG") {
        s_tokenCounter = 0;
    }

    // To create new NFT, call mint() from openzeppelin 721.sol
    function mint() public {
        s_tokenCounter = s_tokenCounter + 1; // everytime we mint a nft, we increase the tokenID

        // calling "_safeMint()" from openzeppelin 721.sol:-> This function takes msg.sender (however calls the mint function make him the holder), tokenId(if this contract holds more than 1 nft than give a unique ID to each one them)
        _safeMint(msg.sender, s_tokenCounter);
    }

    function tokenURI(
        uint256 /*tokenId */
    ) public pure override returns (string memory) {
        return TOKEN_URI;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
}
