//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

struct Loan {
    ERC721 ntfToken;
    uint256 nftTokenId;
    uint256 price;
    uint256 amount;
    uint256 maturity;
    address borrower;
    uint8 status;
}

contract NFTLender {
    uint8 constant STATUS_STARTED = 1;
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

    function startLoan(ERC721 ntfToken, uint256 nftTokenId, uint256 price, uint256 maturity) public {
        console.log("startLoan, loanId: %d", loanNumber);
        console.log("msg.sender: %s", msg.sender);
        console.log("address(this): %s", address(this));

        Loan memory loan = Loan({
            ntfToken: ntfToken,
            nftTokenId: nftTokenId,
            price: price,
            amount: 0,
            maturity: maturity,
            borrower: msg.sender,
            status: STATUS_STARTED
        });

        loans[loanNumber] = loan;

        loanNumber++;

        ntfToken.transferFrom(msg.sender, address(this), nftTokenId);
    }

    function fundLoan(uint256 loanId, uint256 amount) public {
        console.log("fundLoan, loanId: %d", loanId);
        console.log("msg.sender: %s", msg.sender);
        console.log("status: %d", loans[loanId].status);

        require(loans[loanId].status == STATUS_STARTED, "The specified loan cannot be funded");
        require(amount <= (loans[loanId].price * MAX_RATIO) / 100, "The loan amount cannot exceed 70% of the NFT price");

        loans[loanId].amount = amount;
        loans[loanId].status = STATUS_FUNDED;

        usdcToken.transferFrom(msg.sender, loans[loanId].borrower, amount);
    }
}
