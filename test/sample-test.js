const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

describe("Create & cancel", function () {
  var nftLender;
  var usdc;
  var testNft;
  var owner, borrower, lender, liquidator;
  
  it("Deploy contracts", async function () {
    [owner, borrower, lender, liquidator] = await ethers.getSigners();

    const Usdc = await ethers.getContractFactory("USDC");
    usdc = await Usdc.deploy("USDC", "USDC");
    await usdc.deployed();

    const TestNft = await ethers.getContractFactory("TestNFT");
    testNft = await TestNft.deploy("Test NFT", "Test NFT");
    await testNft.deployed();

    // Transfer the NFT to borrower
    await testNft.transferFrom(owner.address, borrower.address, 0);

    const NFTLender = await ethers.getContractFactory("NFTLender");
    nftLender = await NFTLender.deploy(usdc.address);
    await nftLender.deployed();
  });

  it("Create a new loan", async function () {
    await testNft.connect(borrower).approve(nftLender.address, 0);

    const startLoanTx = await nftLender.connect(borrower).createLoan(
      testNft.address,                          // NTF token 
      0,                                        // NFT token Id
      BigNumber.from("100000000000000000000"),  // 100 USDC
      BigNumber.from("200000000000000000"),     // 20%
      60 * 60 * 24 * 10);                       // 10 days

    await startLoanTx.wait();

    expect(await testNft.ownerOf(0)).to.equal(nftLender.address);
  });

  it("Cancel the loan", async function () {
    const cancelLoanTx = await nftLender.connect(borrower).cancelLoan(0);
    await cancelLoanTx.wait();

    expect(await testNft.ownerOf(0)).to.equal(borrower.address);
  });
});

describe("Create & repay", function () {
  var nftLender;
  var usdc;
  var testNft;
  var owner, borrower, lender, liquidator;
  
  it("Deploy contracts", async function () {
    [owner, borrower, lender, liquidator] = await ethers.getSigners();

    const Usdc = await ethers.getContractFactory("USDC");
    usdc = await Usdc.deploy("USDC", "USDC");
    await usdc.deployed();

    // Send 100 USDC to lender
    await usdc.approve(owner.address, ethers.constants.MaxUint256);
    await usdc.transferFrom(owner.address, lender.address, BigNumber.from("100000000000000000000"));

    const TestNft = await ethers.getContractFactory("TestNFT");
    testNft = await TestNft.deploy("Test NFT", "Test NFT");
    await testNft.deployed();

    // Transfer the NFT to borrower
    await testNft.transferFrom(owner.address, borrower.address, 0);

    const NFTLender = await ethers.getContractFactory("NFTLender");
    nftLender = await NFTLender.deploy(usdc.address);
    await nftLender.deployed();
  });

  it("Create a new loan", async function () {
    await testNft.connect(borrower).approve(nftLender.address, 0);

    const startLoanTx = await nftLender.connect(borrower).createLoan(
      testNft.address,                          // NTF token 
      0,                                        // NFT token Id
      BigNumber.from("100000000000000000000"),  // 100 USDC
      BigNumber.from("200000000000000000"),     // 20%
      60 * 60 * 24 * 10);                       // 10 days

    await startLoanTx.wait();

    expect(await testNft.ownerOf(0)).to.equal(nftLender.address);
  });

  it("Fund the loan", async function () {
    var amount = BigNumber.from("70000000000000000000");  // 70 USDC

    await usdc.connect(lender).approve(nftLender.address, ethers.constants.MaxUint256);

    const fundLoanTx = await nftLender.connect(lender).fundLoan(0, amount);
    await fundLoanTx.wait();

    expect(await usdc.balanceOf(borrower.address)).to.equal(amount);
    expect(await testNft.ownerOf(0)).to.equal(nftLender.address);
  });

  it("Repay the loan", async function () {
    var amount = BigNumber.from("70000000000000000000");  // 70 USDC

    // Send 1 USDC to borrower to cover interest
    await usdc.transferFrom(owner.address, borrower.address, BigNumber.from("1000000000000000000"));

    await usdc.connect(borrower).approve(nftLender.address, ethers.constants.MaxUint256);

    const repayLoanTx = await nftLender.connect(borrower).repayLoan(0);
    await repayLoanTx.wait();

    expect(await testNft.ownerOf(0)).to.equal(borrower.address);
  });
});

describe("Create & liquidate", function () {
  var nftLender;
  var usdc;
  var testNft;
  var owner, borrower, lender, liquidator;
  
  it("Deploy contracts", async function () {
    [owner, borrower, lender, liquidator] = await ethers.getSigners();

    const Usdc = await ethers.getContractFactory("USDC");
    usdc = await Usdc.deploy("USDC", "USDC");
    await usdc.deployed();

    // Send 100 USDC to lender and to liquidator
    await usdc.approve(owner.address, ethers.constants.MaxUint256);
    await usdc.transferFrom(owner.address, lender.address, BigNumber.from("100000000000000000000"));
    await usdc.transferFrom(owner.address, liquidator.address, BigNumber.from("100000000000000000000"));

    const TestNft = await ethers.getContractFactory("TestNFT");
    testNft = await TestNft.deploy("Test NFT", "Test NFT");
    await testNft.deployed();

    // Transfer the NFT to borrower
    await testNft.transferFrom(owner.address, borrower.address, 0);

    const NFTLender = await ethers.getContractFactory("NFTLender");
    nftLender = await NFTLender.deploy(usdc.address);
    await nftLender.deployed();
  });

  it("Create a new loan", async function () {
    await testNft.connect(borrower).approve(nftLender.address, 0);

    const startLoanTx = await nftLender.connect(borrower).createLoan(
      testNft.address,                          // NTF token 
      0,                                        // NFT token Id
      BigNumber.from("100000000000000000000"),  // 100 USDC
      BigNumber.from("200000000000000000"),     // 20%
      1);                                       // 1 second

    await startLoanTx.wait();

    expect(await testNft.ownerOf(0)).to.equal(nftLender.address);
  });

  it("Fund the loan", async function () {
    var amount = BigNumber.from("70000000000000000000");  // 70 USDC

    await usdc.connect(lender).approve(nftLender.address, ethers.constants.MaxUint256);

    const fundLoanTx = await nftLender.connect(lender).fundLoan(0, amount);
    await fundLoanTx.wait();

    expect(await usdc.balanceOf(borrower.address)).to.equal(amount);
    expect(await testNft.ownerOf(0)).to.equal(nftLender.address);
  });

  it("Liquidate the loan", async function () {
    await usdc.connect(liquidator).approve(nftLender.address, ethers.constants.MaxUint256);

    const liquidateLoanTx = await nftLender.connect(liquidator).liquidateLoan(0);
    await liquidateLoanTx.wait();

    expect(await testNft.ownerOf(0)).to.equal(liquidator.address);
  });
});
