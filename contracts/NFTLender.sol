//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

struct Loan {
    ERC721 nftToken;
    uint256 nftTokenId;
    uint256 price;
    uint256 rate;
    uint256 amount;
    uint256 maturity;
    address borrower;
    address lender;
    uint256 timeFunded;
    uint8 status;
}

contract NFTLender {
    uint8 constant STATUS_NEW = 1;
    uint8 constant STATUS_FUNDED = 2;
    uint8 constant STATUS_REPAID = 3;
    uint8 constant STATUS_LIQUIDATED = 4;

    uint8 constant MAX_RATIO = 70;

    uint256 loanNumber = 0;
    mapping (uint256 => Loan) public loans;
    ERC20 usdcToken;

    constructor(ERC20 _usdcToken) {
        console.log("NFTLender constructor");
        usdcToken = _usdcToken;
    }

    function createLoan(ERC721 nftToken, uint256 nftTokenId, uint256 price, uint256 rate, uint256 maturity) public {
        console.log("startLoan, loanId: %d", loanNumber);
        console.log("msg.sender: %s", msg.sender);
        console.log("address(this): %s", address(this));

        require(price > 0, "The price cannot be negative");
        require(rate > 0, "The rate cannot be negative");
        require(maturity > 0, "The maturity cannot be negative");

        Loan memory loan = Loan({
            nftToken: nftToken,
            nftTokenId: nftTokenId,
            price: price,
            rate: rate,
            amount: 0,
            maturity: maturity,
            borrower: msg.sender,
            lender: 0x0000000000000000000000000000000000000000,
            timeFunded: 0,
            status: STATUS_NEW
        });

        loans[loanNumber] = loan;

        loanNumber++;

        nftToken.transferFrom(msg.sender, address(this), nftTokenId);
    }

    function fundLoan(uint256 loanId, uint256 amount) public {
        console.log("fundLoan, loanId: %d", loanId);
        console.log("msg.sender: %s", msg.sender);
        console.log("status: %d", loans[loanId].status);

        require(loans[loanId].status == STATUS_NEW, "The specified loan cannot be funded");
        require(amount <= (loans[loanId].price * MAX_RATIO) / 100, "The loan amount cannot exceed 70% of the NFT price");

        loans[loanId].amount = amount;
        loans[loanId].lender = msg.sender;
        loans[loanId].timeFunded = block.timestamp;
        loans[loanId].status = STATUS_FUNDED;

        usdcToken.transferFrom(msg.sender, loans[loanId].borrower, amount);
    }

    function repayLoan(uint256 loanId) public {
        console.log("repayLoan, loanId: %d", loanId);
        console.log("msg.sender: %s", msg.sender);
        console.log("status: %d", loans[loanId].status);
        console.log("now: %d", block.timestamp);

        require(loans[loanId].status == STATUS_FUNDED, "The specified loan cannot be repaid");
        require(msg.sender == loans[loanId].borrower, "This method can only be called by borrower");

        uint256 elapsedTime = block.timestamp - loans[loanId].timeFunded;

        require(elapsedTime < loans[loanId].maturity, "This loan has reached maturity");

        uint256 repaymentAmount = _computeRepaymentAmount(loanId, elapsedTime);

        loans[loanId].status = STATUS_REPAID;

        ERC721 nftToken = loans[loanId].nftToken;

        usdcToken.transferFrom(loans[loanId].borrower, loans[loanId].lender, repaymentAmount);
        nftToken.transferFrom(address(this), loans[loanId].borrower, loans[loanId].nftTokenId);
   }

    function liquidateLoan(uint256 loanId) public {
        console.log("liquidateLoan, loanId: %d", loanId);
        console.log("msg.sender: %s", msg.sender);
        console.log("status: %d", loans[loanId].status);
        console.log("now: %d", block.timestamp);

        require(loans[loanId].status == STATUS_FUNDED, "The specified loan cannot be liquidated");

        uint256 elapsedTime = block.timestamp - loans[loanId].timeFunded;

        require(loans[loanId].maturity <= elapsedTime, "This loan has not reached maturity");

        uint256 repaymentAmount = _computeRepaymentAmount(loanId, elapsedTime);

        loans[loanId].status = STATUS_LIQUIDATED;

        ERC721 nftToken = loans[loanId].nftToken;

        usdcToken.transferFrom(msg.sender, loans[loanId].lender, repaymentAmount);
        nftToken.transferFrom(address(this), msg.sender, loans[loanId].nftTokenId);
    }

    function _computeRepaymentAmount(uint256 loanId, uint256 elapsedTime) private view returns (uint256) {
        console.log("elapsedTime: %d", elapsedTime);

        uint256 ratePerSecond = loans[loanId].rate / 31536000;
        uint256 accruedInterest = (loans[loanId].amount * elapsedTime * ratePerSecond) / 1000000000000000000;
        uint256 repaymentAmount = loans[loanId].amount + accruedInterest;

        console.log("repaymentAmount: %d", repaymentAmount);

        return repaymentAmount;
    }
}
