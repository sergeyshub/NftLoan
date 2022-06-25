//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

// @dev Loan data
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

/* @title   NFTLender
 *
 * @author  Sergey Nikitin
 *
 * @notice  Loans USDC using any NFT as collateral.
 *
 *          The assignment didn't specify if the loans should be made from a loan pool
 *          or peer-to-peer between users. Given that a pool would not be able to determine
 *          the price of NFT automatically, I made the decision to design a peer-to-peer
 *          lending algorithm.
 *      
 *          The process:
 *
 *          1. A borrower creates a loan and specifies the price of collateral and the desired terms
 *          2. A lender, if he/she likes the terms and finds the price fair, funds the loan
 *          3. The borrower can repay the principal and interest and receive the collateral back
 *          4. If the loan reaches maturity, any user can repay the principal and interest and
 *          receive the collateral 
 *          5. Until the loan is funded by a lender, the borrower can cancel it and get the collateral
 *          back
 *
 * @dev     This contract doesn't use safe math (we don't expect to overflow with this test) and 
 *          doesn't have any admin methods, so not using the Ownable pattern.
 */
contract NFTLender {
    uint8 constant STATUS_NEW = 1;
    uint8 constant STATUS_FUNDED = 2;
    uint8 constant STATUS_REPAID = 3;
    uint8 constant STATUS_LIQUIDATED = 4;
    uint8 constant STATUS_CANCELED = 5;

    uint8 constant MAX_RATIO = 70;      // max amount to price ratio 70%

    uint256 loanNumber = 0;
    mapping (uint256 => Loan) public loans;
    ERC20 usdcToken;

    /* @notice   Constructor
     *
     * @param    _usdcToken - the token to use for loan payments (has to be USDC per assignment)
     */
    constructor(ERC20 _usdcToken) {
        console.log("NFTLender constructor");
        usdcToken = _usdcToken;
    }

    /* @notice   Creates a new loan
     *
     * @param    nftToken - NFT token to use as collateral
     * @param    nftTokenId - NFT token id
     * @param    price - NFT token price, as determined by the borrower multipled by 10**18
     * @param    rate - annual percentage rate multipled by 10**18. Example: 200000000000000000 is 20%
     * @param    maturity - loan maturity time in seconds
     */
    function createLoan(ERC721 nftToken, uint256 nftTokenId, uint256 price, uint256 rate, uint256 maturity) public returns (uint256) {
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

        // Not checking allowance, as this will just revert if not set or insufficient
        nftToken.transferFrom(msg.sender, address(this), nftTokenId);

        return loanNumber - 1;
    }

    /* @notice   Cancels a new (unfunded) loan, can only be called by borrower
     *
     * @param    loanId - loan Id
     */
    function cancelLoan(uint256 loanId) public {
        console.log("repayLoan, loanId: %d", loanId);
        console.log("msg.sender: %s", msg.sender);
        console.log("status: %d", loans[loanId].status);

        require(loans[loanId].status == STATUS_NEW, "The specified loan cannot be canceled");
        require(msg.sender == loans[loanId].borrower, "This method can only be called by borrower");

        loans[loanId].status = STATUS_CANCELED;

        ERC721 nftToken = loans[loanId].nftToken;

        // The allowance for the NFT token was already set prior to calling createLoan()
        nftToken.transferFrom(address(this), loans[loanId].borrower, loans[loanId].nftTokenId);
   }

    /* @notice   Funds a new loan
     *
     * @param    loanId - loan Id
     * @param    amount - loan amount, must be greater than 0 and not greater than 70% of the NTF price
     */
    function fundLoan(uint256 loanId, uint256 amount) public {
        console.log("fundLoan, loanId: %d", loanId);
        console.log("msg.sender: %s", msg.sender);
        console.log("status: %d", loans[loanId].status);

        require(loans[loanId].status == STATUS_NEW, "The specified loan cannot be funded");
        require(amount > 0, "The loan amount cannot be negative");
        require(amount <= (loans[loanId].price * MAX_RATIO) / 100, "The loan amount cannot exceed 70% of the NFT price");

        loans[loanId].amount = amount;
        loans[loanId].lender = msg.sender;
        loans[loanId].timeFunded = block.timestamp;
        loans[loanId].status = STATUS_FUNDED;

        // Not checking allowance, as this will just revert if not set or insufficient
        usdcToken.transferFrom(msg.sender, loans[loanId].borrower, amount);
    }

    /* @notice   Repays a loan, can only be called by borrower
     *
     * @param    loanId - loan Id
     */
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

        // Not checking allowance, as this will just revert if not set or insufficient
        usdcToken.transferFrom(loans[loanId].borrower, loans[loanId].lender, repaymentAmount);
        nftToken.transferFrom(address(this), loans[loanId].borrower, loans[loanId].nftTokenId);
   }

    /* @notice   Liquidates a loan
     *
     * @param    loanId - loan Id
     */
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

        // Not checking allowance, as this will just revert if not set or insufficient
        usdcToken.transferFrom(msg.sender, loans[loanId].lender, repaymentAmount);
        nftToken.transferFrom(address(this), msg.sender, loans[loanId].nftTokenId);
    }

    /* @notice   Computes repayment amount
     *
     * @param    loanId - loan Id
     * @param    elapsedTime - elapsed time since loan funding in seconds
     */
    function _computeRepaymentAmount(uint256 loanId, uint256 elapsedTime) private view returns (uint256) {
        console.log("elapsedTime: %d", elapsedTime);

        uint256 ratePerSecond = loans[loanId].rate / 31536000;
        uint256 accruedInterest = (loans[loanId].amount * elapsedTime * ratePerSecond) / 1000000000000000000;
        uint256 repaymentAmount = loans[loanId].amount + accruedInterest;

        console.log("repaymentAmount: %d", repaymentAmount);

        return repaymentAmount;
    }
}
