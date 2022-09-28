/**
 * @dev In this contract we are using Chainlink ETH Price to make Dynamic SVG NFT
 * @dev we need to convert SVG to ImageUri.
 * In order to do this we can use Base64-encoding to convert our SVG to Binary-Data which we can excess via `data:image/svg+xml;base64,'Binary-Data'`
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "base64-sol/base64.sol";
import "hardhat/console.sol";

error ERC721Metadata__URI_QueryFor_NonExistentToken();

contract DynamicSvgNft is ERC721, Ownable {
    uint256 private s_tokenCounter;
    string private s_lowImageURI;
    string private s_highImageURI;

    mapping(uint256 => int256) private s_tokenIdToHighValues;
    AggregatorV3Interface internal immutable i_priceFeed;
    event CreatedNFT(uint256 indexed tokenId, int256 highValue);

    constructor(
        address priceFeedAddress,
        string memory lowSvg,
        string memory highSvg
    ) ERC721("Dynamic SVG NFT", "DSN") {
        s_tokenCounter = 0;
        i_priceFeed = AggregatorV3Interface(priceFeedAddress);
        //  NOTE this below code is to store our svg "On-Chain"
        s_lowImageURI = svgToImageURI(lowSvg);
        s_highImageURI = svgToImageURI(highSvg);
    }

    /**
     * @dev This function will convert our SVG to readable IMAGE URI (the uri in metadata image keypair)
     */
    function svgToImageURI(string memory svg) public pure returns (string memory) {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));
        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }

    /**
     * @dev Mint Function
     * Let Minter choose on which value they wanna mint the nft "low" or "high"
     */
    function mintNft(int256 highValue) public {
        s_tokenIdToHighValues[s_tokenCounter] = highValue;
        s_tokenCounter += s_tokenCounter;
        _safeMint(msg.sender, s_tokenCounter);

        emit CreatedNFT(s_tokenCounter, highValue);
    }

    /**
     * @dev This (ERC721)function will return the prefix for "json Base64 encoded data"
     */
    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    /**
     * @dev This (ERC721)function will encode the metadata (json) into base64 based TokenURI.
     * which we will use as "tokenURI"
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721Metadata__URI_QueryFor_NonExistentToken();
        }

        (, int256 price, , , ) = i_priceFeed.latestRoundData();

        string memory imageURI = s_lowImageURI;

        if (price >= s_tokenIdToHighValues[tokenId]) {
            imageURI = s_highImageURI;
        }

        return
            string(
                // Concatenating the "json" prefix with "base64" encode data. To get the json data.
                abi.encodePacked(
                    _baseURI(),
                    // Below code will encoded in Base64
                    Base64.encode(
                        // Below code will return a bytes data
                        bytes(
                            // below code will create json data by concatenating the strings
                            abi.encodePacked(
                                '{"name":"',
                                name(),
                                '", "description":"An NFT that changes based on the Chainlink PriceFeed", ',
                                '"attributes": [{"trait_type": "coolness", "value": 100}], "image":"',
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    function getLowSVG() public view returns (string memory) {
        return s_lowImageURI;
    }

    function getHighSVG() public view returns (string memory) {
        return s_highImageURI;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return i_priceFeed;
    }
}
