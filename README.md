# NFT Royalty Exchange

A specialized marketplace contract that respects and enforces creator royalties. While many marketplaces make royalties optional, this implementation queries the NFT contract directly using the EIP-2981 interface to calculate and distribute fees during the "Atomic Swap."

## Features
* **EIP-2981 Integration**: Automatically calculates royalties for compliant NFT collections.
* **Escrow-less Listing**: Users keep NFTs in their wallets until the moment of sale (requires approval).
* **Pull-Payment Pattern**: Securely handles fund distribution to prevent reentrancy during mass transfers.

## Architecture
1. **Listing**: Seller approves the marketplace and sets a price.
2. **Purchase**: Buyer sends ETH.
3. **Distribution**: The contract splits the ETH into:
   - Creator Royalty (sent to creator)
   - Sale Price (sent to seller)
