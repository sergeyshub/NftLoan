const { expect } = require("chai");
const { ethers } = require("hardhat");

var nftLender;
var testNft;

describe("NFTLender", function () {
  it("Should create a test NFT token", async function () {
    const TestNft = await ethers.getContractFactory("TestNFT");
    testNft = await TestNft.deploy("Test NFT", "Test NFT");
    await testNft.deployed();

    expect(await testNft.name()).to.equal("Test NFT");

    // console.log(`Owner of 0: ${await testNFT.ownerOf(0)}`);
  });

  it("Should deploy NFTLender contract", async function () {
    const NFTLender = await ethers.getContractFactory("NFTLender");
    nftLender = await NFTLender.deploy();
    await nftLender.deployed();
  });

  it("Should start a loan", async function () {
    await testNft.approve(nftLender.address, 0);

    const startLoanTx = await nftLender.startLoan(testNft.address, 0, 100000);
    await startLoanTx.wait();
  });
});
