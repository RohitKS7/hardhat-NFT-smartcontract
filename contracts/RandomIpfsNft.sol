/**
 * @dev When we call the mint function, we will trigger the Chainlink VRF.
 * which will give us a random number and with this random number,
 * we will get a random NFT.
 * @dev Setting NFT rarity
 * @dev user will be paying for NFT. and Artists can Withdraw there payments.
 * @dev We are using ERC721URIStorage.sol instead of ERC721.sol to get extra functions
 * like: _setTokenURI() = sets tokenUri of with tokenId
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "hardhat/console.sol";

error RandomIpfsNft__RangeOutOfBounds();
error RandomIpfsNft__NotEnoughMintFee();
error RandomIpfsNft__YouAreNotOwner();

contract RandomIpfsNft is VRFConsumerBaseV2, ERC721URIStorage, Ownable {
    enum PFP {
        BEST_PFP, // index = 1
        PFP_WITHOUT_BG, // index = 2
        PFP_WITH_BG // index = 3
    }

    // Chainlink VRF variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gaslane;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    // VRF helper variables
    mapping(uint256 => address) public s_requestIdSender;

    // NFT Variables
    uint256 private s_tokenCounter;
    uint256 internal constant MAX_CHANCE_VALUE = 100;
    string[] internal s_pfpTokenUris;
    uint256 internal immutable i_mintFee;

    // Events
    event NftRequested(uint256 indexed requestId, address requester);
    event NftMinted(PFP pfpType, address minter);

    /**
     * @dev VRFConsumerBaseV2 have a constructor which takes address of VRFCoordinatorV2
     * and we will get that address from chainlink docs for testnets
     * and for local node from vrfCoordinatorV2Mock.sol
     */
    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gaslane,
        uint32 callbackGasLimit,
        uint256 mintFee,
        string[3] memory pfpTokenUris
    ) VRFConsumerBaseV2(vrfCoordinatorV2) ERC721("Random IPFS NFT", "RIN") {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_subscriptionId = subscriptionId;
        i_gaslane = gaslane;
        i_callbackGasLimit = callbackGasLimit;
        i_mintFee = mintFee;
        s_pfpTokenUris = pfpTokenUris;
    }

    /**
     * @dev Pay to call this function
     * @dev reqestNFT() will trigger the VRF to get the random number
     * and in-order to get the random NFT(or number),
     * @dev We have to call "COORDINATOR.requestRandomWords()" + his parameters
     * @return requestId = its the random number.
     */
    function requestNFT() public payable returns (uint256 requestId) {
        if (msg.value < i_mintFee) {
            revert RandomIpfsNft__NotEnoughMintFee();
        }

        requestId = i_vrfCoordinator.requestRandomWords(
            i_gaslane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        // whoever calls this requestNFT function and gets a random requestId number map there address to this requestId. So, fulfillRandomWords() will check if requestId is mapped by any address, to make them the NFT holder.
        s_requestIdSender[requestId] = msg.sender;

        emit NftRequested(requestId, msg.sender);
    }

    /**
     * @dev fulfillRandomWords() will get the random number and
     * @dev We will call getPFPFromModdedRng() here and
     * will get the NFT's in different rarities order
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address nftOwner = s_requestIdSender[requestId];
        uint256 newTokenId = s_tokenCounter;

        uint256 moddedRng = randomWords[0] % MAX_CHANCE_VALUE;
        // will return number b/w 0-99
        // 0 - 10 => PUG
        // 11 - 30 => Shiba INU
        // 31 - 100 => St. Bernard

        PFP pfpType = getPFPFromModdedRng(moddedRng);
        s_tokenCounter += s_tokenCounter;
        _safeMint(nftOwner, newTokenId);
        _setTokenURI(newTokenId, s_pfpTokenUris[uint256(pfpType)]);

        emit NftMinted(pfpType, nftOwner);
    }

    /**
     * @dev Withdraw function which only allows owner to withdraw the NFT,
     * for that we can make onlyOwner modifer or
     * use openzeppelin's Ownable.sol to get it.
     */

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert RandomIpfsNft__YouAreNotOwner();
        }
    }

    /**
     * @dev With getChanceArray function we're giving the rarity percentage to NFT's.
     * index 1 = 10% chance
     * index 2 = 30% chance
     * index 3 = 10 + 30 - 100 = 60% chance
     */

    function getChanceArray() public pure returns (uint256[3] memory) {
        return [10, 30, MAX_CHANCE_VALUE];
    }

    /**
     * @dev Function to set Rarity of NFT's
     */
    function getPFPFromModdedRng(uint256 moddedRng) public pure returns (PFP) {
        uint256 cumualtiveSum = 0;
        uint256[3] memory chanceArray = getChanceArray();
        for (uint256 i = 0; i < chanceArray.length; i++) {
            if (moddedRng >= cumualtiveSum && moddedRng < cumualtiveSum + chanceArray[i]) {
                return PFP(i);
            }
            cumualtiveSum += chanceArray[i];
            // Above line means this => cumualtiveSum = cumualtiveSum + chanceArray[i]
        }

        revert RandomIpfsNft__RangeOutOfBounds();
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    function getMintFee() public view returns (uint256) {
        return i_mintFee;
    }

    function getPfpTokenUris(uint256 index) public view returns (string memory) {
        return s_pfpTokenUris[index];
    }
}
