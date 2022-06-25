const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

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

  it("Create a new loan", async function () {
    await testNft.approve(nftLender.address, 0);

    const startLoanTx = await nftLender.createLoan(
      testNft.address,                          // NTF token 
      0,                                        // NFT token Id
      BigNumber.from("100000000000000000000"),  // 100 USDC
      BigNumber.from("200000000000000000"),     // 20%
      60 * 60 * 24 * 10);                       // 10 days

    await startLoanTx.wait();
  });

  /*
  it("Cancel the loan", async function () {
    const cancelLoanTx = await nftLender.cancelLoan(0);
    await cancelLoanTx.wait();
  });
  */

  it("Fund the loan", async function () {
    var amount = BigNumber.from("70000000000000000000");  // 70 USDC

    await usdc.approve(nftLender.address, ethers.constants.MaxUint256);

    const fundLoanTx = await nftLender.fundLoan(0, amount);
    await fundLoanTx.wait();
  });

  it("Repay the loan", async function () {
    await usdc.approve(nftLender.address, ethers.constants.MaxUint256);

    const repayLoanTx = await nftLender.repayLoan(0);
    await repayLoanTx.wait();
  });

  /*
  it("Liquidate the loan", async function () {
    await usdc.approve(nftLender.address, ethers.constants.MaxUint256);

    const liquidateLoanTx = await nftLender.liquidateLoan(0);
    await liquidateLoanTx.wait();
  });
  */
});
