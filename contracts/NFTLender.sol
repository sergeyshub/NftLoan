//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

struct Loan {
    uint256 loanId;
    ERC721 ntfToken;
    uint256 nftTokenId;
    uint256 price;
}

contract NFTLender {
    uint256 loanNumber = 0;
    mapping (uint256 => Loan) public loans;

    constructor() {
        console.log("NFTLender constructor");
    }

    function startLoan(ERC721 ntfToken, uint256 nftTokenId, uint256 price) public {
        console.log("startLoan, loanNumber: %d", loanNumber);
        console.log("msg.sender: %s", msg.sender);
        console.log("address(this): %s", address(this));

        ntfToken.transferFrom(msg.sender, address(this), nftTokenId);

        Loan memory loan = Loan({
            loanId: loanNumber,
            ntfToken: ntfToken,
            nftTokenId: nftTokenId,
            price: price
        });

        loans[loanNumber] = loan;

        loanNumber++;
    }
}
