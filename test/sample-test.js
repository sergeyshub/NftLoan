const { expect } = require("chai");
const { ethers } = require("hardhat");

var nftLender;
var usdc;
var testNft;

describe("NFTLender", function () {
  it("Create test USDC", async function () {
    const Usdc = await ethers.getContractFactory("USDC");
    usdc = await Usdc.deploy("USDC", "USDC");
    await usdc.deployed();

    expect(await usdc.name()).to.equal("USDC");
  });

  it("Create a test NFT token", async function () {
    const TestNft = await ethers.getContractFactory("TestNFT");
    testNft = await TestNft.deploy("Test NFT", "Test NFT");
    await testNft.deployed();

    expect(await testNft.name()).to.equal("Test NFT");

    // console.log(`Owner of 0: ${await testNFT.ownerOf(0)}`);
  });

  it("Deploy NFTLender contract", async function () {
    const NFTLender = await ethers.getContractFactory("NFTLender");
    nftLender = await NFTLender.deploy(usdc.address);
    await nftLender.deployed();
  });

  it("Start a loan", async function () {
    await testNft.approve(nftLender.address, 0);

    const startLoanTx = await nftLender.startLoan(testNft.address, 0, 100000, 60 * 60 * 24 * 10);
    await startLoanTx.wait();
  });

  it("Fund the loan", async function () {
    var amount = 70000;

    await usdc.approve(nftLender.address, amount);

    const fundLoanTx = await nftLender.fundLoan(0, amount);
    await fundLoanTx.wait();
  });
});
