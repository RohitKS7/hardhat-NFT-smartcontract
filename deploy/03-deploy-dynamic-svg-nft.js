const { network, ethers } = require("hardhat")
const { networkConfig, developmentChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")
const fs = require("fs")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId
    let ethUsdPriceFeedAddress

    if (chainId === 31337) {
        const priceFeedFromMockV3 = await deployments.get("MockV3Aggregator")
        ethUsdPriceFeedAddress = priceFeedFromMockV3.address
    } else {
        ethUsdPriceFeedAddress = networkConfig[chainId].ethUsdPriceFeed
    }

    const lowSvg = fs.readFileSync("./images/dynamicNft/frown.svg", { encoding: "utf8" })
    const highSvg = fs.readFileSync("./images/dynamicNft/happy.svg", { encoding: "utf8" })

    log("----------------------------------------------------")

    const arguments = [ethUsdPriceFeedAddress, lowSvg, highSvg]

    log("Deploying DynamicSvgNft contract....")

    const dynamicSvgNft = await deploy("DynamicSvgNft", {
        from: deployer,
        args: arguments,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })

    log("Deployed!!! DynamicSvgNft")

    //  Verify the deployment
    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(dynamicSvgNft.address, arguments)
    }
    log("Verified!! for dynamicSvgNft")
    log("----------------------------------------------------")
}
module.exports.tags = ["all", "dynamicsvg", "main"]
