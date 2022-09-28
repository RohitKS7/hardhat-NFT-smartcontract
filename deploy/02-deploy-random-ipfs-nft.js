const { ethers, network } = require("hardhat")
const { developmentChains, networkConfig } = require("../helper-hardhat-config")
const { storeImages, storeTokenUriMetadata } = require("../utils/uploadToPinata")
const { verify } = require("../utils/verify")

const imagesLocation = "./images/randomNft"

const metadataTemplate = {
    name: "",
    description: "",
    image: "",
    attributes: [
        {
            Background: "Colored / Transparent",
        },
    ],
}

// There should not have any array but since we already uploaded our images and make the `UPLOAD_TO_PINATA = false` in .emv file. To not upload Images again and again which will take time and processor.
let tokenUris = [
    "ipfs://QmQnnA6KyStjgf64aqTNajv7oJ7MxqtGb5FhhDW6c5HQ6M",
    "ipfs://QmZtZsY5MMVfWxkpDvL8EgUEnytfBhhJ5rwXuCwgqonXq5",
    "ipfs://QmSutH9Sx18TD2FhMwKz389epVuJRNEq5KDpboctvzjA5q",
]

const FUND_AMOUNT = ethers.utils.parseEther("10")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    chainId = network.config.chainId

    // get the IPFS hashes of our images
    if (process.env.UPLOAD_TO_PINATA == "true") {
        tokenUris = await handleTokenUris()
    }

    let vrfCoordinatorV2Address, subscriptionId

    if (developmentChains.includes(network.name)) {
        const vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock")
        vrfCoordinatorV2Address = vrfCoordinatorV2Mock.address
        const tx = await vrfCoordinatorV2Mock.createSubscription()
        const txReceipt = await tx.wait(1)
        subscriptionId = txReceipt.events[0].args.subId
        await vrfCoordinatorV2Mock.fundSubscription(subscriptionId, FUND_AMOUNT)
    } else {
        vrfCoordinatorV2Address = networkConfig[chainId].vrfCoordinatorV2
        subscriptionId = networkConfig[chainId].subscriptionId
    }

    log("----------------------------------------------------")
    log("Getting Images.....")
    await storeImages(imagesLocation)

    arguments = [
        vrfCoordinatorV2Address,
        subscriptionId,
        networkConfig[chainId].gasLane,
        networkConfig[chainId].callbackGasLimit,
        networkConfig[chainId].mintFee,
        tokenUris,
    ]

    log("Deploying randomIpfsNft contract....")
    const randomIpfsNft = await deploy("RandomIpfsNft", {
        from: deployer,
        args: arguments,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })
    log("Deployed!!! randomIpfsNft")
    log("----------------------------------------------------")

    // Verify the deployment
    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(randomIpfsNft.address, arguments)
    }
    log("Verified!! for RandomIpfsNft")
    log("----------------------------------------------------")
}

// TODO
// 1. Store Images on IPFS. [done]
// 2. Store Metadata on IPFS. [done]
async function handleTokenUris() {
    tokenUris = []

    // Get responses (which have hashes of all images) and files from uploadToPinata.js
    const { responses: imageUploadResponses, files } = await storeImages(imagesLocation)

    // Now we'll loop through each image and
    // Create Metadata
    // Upload the Metadata
    for (imageUploadResponseIndex in imageUploadResponses) {
        let tokenUriMetadata = { ...metadataTemplate } // spread operator in object will open the object to get the inner keypair
        tokenUriMetadata.name = files[imageUploadResponseIndex].replace(".png", "")
        tokenUriMetadata.description = `PFP Images of Rohit Kumar Suman`
        tokenUriMetadata.image = `ipfs://${imageUploadResponses[imageUploadResponseIndex].IpfsHash}`
        console.log(`Uploading ${tokenUriMetadata.name}...`)
        // uploading metadata on IPFS
        const metadataUploadResponse = await storeTokenUriMetadata(tokenUriMetadata)
        tokenUris.push(`ipfs://${metadataUploadResponse.IpfsHash}`)
    }
    console.log("Token URIs Uploaded! They are:")
    console.log(tokenUris)
    return tokenUris
}

module.exports.tags = ["all", "randomipfsnft", "main"]
