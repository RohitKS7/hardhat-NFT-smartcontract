const { assert, expect } = require("chai")
const { network, deployments, ethers } = require("hardhat")
const { developmentChains } = require("../../helper-hardhat-config")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Basic NFT Unit Tests", function () {
          let randomIpfsNft, vrfCoordinatorV2Mock, deployer

          beforeEach(async () => {
              accounts = await ethers.getSigners()
              deployer = accounts[0]
              await deployments.fixture(["all"])
              randomIpfsNft = await ethers.getContract("RandomIpfsNft")
              vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock")
          })

          describe("constructor", () => {
              it("it initialize the contract correctly", async () => {
                  const tokenUris = await randomIpfsNft.getPfpTokenUris(0)
                  assert(tokenUris.includes("ipfs://"))
              })
          })

          describe("requestNFT", () => {
              it("fails if payment isn't sent with the request", async () => {
                  await expect(randomIpfsNft.requestNFT()).to.be.revertedWith(
                      "RandomIpfsNft__NotEnoughMintFee"
                  )
              })
              it("will fails if payment is less than mintfee", async () => {
                  const mintPayment = ethers.utils.parseEther("0.001")
                  await expect(randomIpfsNft.requestNFT({ value: mintPayment })).to.be.revertedWith(
                      "RandomIpfsNft__NotEnoughMintFee"
                  )
              })
              it("emits an event and kicks off a random word request", async function () {
                  const fee = await randomIpfsNft.getMintFee()
                  await expect(randomIpfsNft.requestNFT({ value: fee.toString() })).to.emit(
                      randomIpfsNft,
                      "NftRequested"
                  )
              })
          })

          describe("fulfillRandomWords", () => {
              it("mints NFT after random number is returned", async function () {
                  await new Promise(async (resolve, reject) => {
                      randomIpfsNft.once("NftMinted", async () => {
                          try {
                              const tokenUri = await randomIpfsNft.tokenURI("0")
                              const tokenCounter = await randomIpfsNft.getTokenCounter()
                              assert.equal(tokenUri.toString().includes("ipfs://"), true)
                              assert.equal(tokenCounter.toString(), "0")
                              resolve()
                          } catch (e) {
                              console.log(e)
                              reject(e)
                          }
                      })
                      try {
                          const fee = await randomIpfsNft.getMintFee()
                          const requestNftResponse = await randomIpfsNft.requestNFT({
                              value: fee.toString(),
                          })
                          const requestNftReceipt = await requestNftResponse.wait(1)
                          await vrfCoordinatorV2Mock.fulfillRandomWords(
                              requestNftReceipt.events[1].args.requestId,
                              randomIpfsNft.address
                          )
                      } catch (e) {
                          console.log(e)
                          reject(e)
                      }
                  })
              })
          })
          describe("getPFPFromModdedRng", () => {
              it("should return BEST_PFP if moddedRng < 10", async function () {
                  const expectedValue = await randomIpfsNft.getPFPFromModdedRng(7)
                  assert.equal(0, expectedValue)
              })
              it("should return PFP_WITHOUT_BG if moddedRng is between 10 - 39", async function () {
                  const expectedValue = await randomIpfsNft.getPFPFromModdedRng(21)
                  assert.equal(1, expectedValue)
              })
              it("should return PFP_WITH_BG if moddedRng is between 40 - 99", async function () {
                  const expectedValue = await randomIpfsNft.getPFPFromModdedRng(77)
                  assert.equal(2, expectedValue)
              })
              it("should revert if moddedRng > 99", async function () {
                  try {
                      await expect(randomIpfsNft.getPFPFromModdedRng(101)).to.be.revertedWith(
                          "RandomIpfsNft__RangeOutOfBounds"
                      )
                  } catch (error) {
                      console.log(error)
                  }
              })
          })
      })
