# Tokenized RWA

Buying RWA:
- only the contract owner can mint the RWA
- anyone can redeem the RWA for USDC or "the stablecoin" of choice.
- chainlink functions will initite the RWA sell for USDC, and then send it to the contract
- the user will have to then call finishRedeem to get their USDC.

Selling RWA:
- users can send USDC -> RWA.sol via sendMintRequest via Chainlink Functions. This will kick off the following:
    - USDC will be sent to Alpaca
    - USDC will be sold for USD
    - USD will be used to buy RWA shares
    - The Chainlink Functions will then callback to _mintFulFillRequest, to enable RWA tokens to the user.
    - The user can then call finishMint to withdraw their minted RWA tokens.
