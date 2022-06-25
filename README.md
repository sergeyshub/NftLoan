# NFT Lender

This project contains a simple peer-to-peer lender that functions according to the requirements:

1. The smart contract should allow a user to borrow USDC by using an NFT as a collateral.
2. The borrowable amount (the loan principal) may not exceed 70% of the NFT’s price.
3. The borrower must repay the loan within some time period (e.g. 24 hours) after taking it.
4. The borrower may repay the loan at any point before the deadline, by making a single payment
covering the principal amount plus the interest for the elapsed time.
5. If the borrower fails to repay the loan by the deadline, allow any user to liquidate the collateral
by making a payment equal to the principal the interest.
6. To keep the contract simple, assume the price of the NFT (in USDC) is constant.

To run, clone the repository and run npm install. Then, open two terminal windows/command prompts:

In prompt one, run:

    npx hardhat node

In prompt two, run:

    npx hardhat test --network localhost

Sample output:

  Create & cancel
    √ Deploy contracts (1404ms)
    √ Create a new loan (1269ms)
    √ Cancel the loan (435ms)

  Create & repay
    √ Deploy contracts (801ms)
    √ Create a new loan (533ms)
    √ Fund the loan (541ms)
    √ Repay the loan (590ms)

  Create & liquidate
    √ Deploy contracts (941ms)
    √ Create a new loan (427ms)
    √ Fund the loan (388ms)
    √ Liquidate the loan (474ms)

  11 passing (8s)
