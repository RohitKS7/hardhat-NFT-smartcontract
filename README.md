# SETUP

This Repo consists 3 contracts:

1. Basic NFT
2. Random IPFS NFT
3. Dynamic SVG NFT (hosted on-chain)

# What we'll learn from this Repo

1. How to use ERC721 EIP (Ethereum Improvement Proposals) to create NFT.

2. How to use Chainlink VRF to setup Random NFT Mint Function.

3. How to store your NFT assests on IPFS.

   There are multiple ways to do that -

   1. Upload it on Your own IPFS Node (GUI or CLI or Scripts).

      > Do remember that pinning your assests on IPFS is the most important thing. You can pin it but what if your system node go down. So, In order to it(assests) remain on IPFS and work properly, some other nodes also have to pin your Data.

      > In order to achieve this there are 2 platforms - 
      Pinata(paid) and nft.storage(free)

   2. With Pinata: It's a paid centralized application which will
      pin your data.

   3. With NFT.STORAGE: It's a free decentralized platform by IPFS
      in front and Filecoin in back.

and We are going to learn how to upload our assests on Pinata and NFT.storage Programmitically.
   
# Deploying and Minting

First Deploy all the contracts on chain or testnet, Then run the mint script to mint 1 NFT from each one of the contracts.
  
   