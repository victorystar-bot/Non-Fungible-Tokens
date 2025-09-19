# NFT Marketplace Smart Contract

A comprehensive decentralized marketplace built on the Stacks blockchain for trading Non-Fungible Tokens (NFTs). This smart contract enables creators and collectors to buy, sell, and auction digital assets with automated fee distribution and collection analytics.

## Features

### Core Marketplace Features
- **Multiple Listing Types**: Fixed price, auction, and Dutch auction support
- **Automated Bidding**: Secure bid handling with automatic refunds for outbid users
- **Dynamic Pricing**: Dutch auctions with decreasing prices over time
- **Instant Purchases**: Buy-now functionality for fixed price listings
- **Flexible Duration**: Configurable listing and auction periods
- **Rich Metadata**: Comprehensive NFT information storage

### Trading & Economics
- **Automated Fee Distribution**: Marketplace and royalty fees automatically distributed
- **Collection Analytics**: Real-time floor prices, volume, and sales tracking
- **User Profiles**: Creator and collector profiles with verification system
- **Bidding History**: Complete auction bid tracking and history
- **Price Discovery**: Market-driven pricing through auctions and sales data

### NFT Categories Supported
- Digital Art (`CATEGORY-ART`)
- Collectibles (`CATEGORY-COLLECTIBLE`)
- Gaming Assets (`CATEGORY-GAMING`)
- Utility Tokens (`CATEGORY-UTILITY`)
- Music & Audio (`CATEGORY-MUSIC`)

### Listing Status Management
- Active (`STATUS-ACTIVE`) - Available for trading
- Sold (`STATUS-SOLD`) - Successfully completed transaction
- Cancelled (`STATUS-CANCELLED`) - Removed by seller
- Expired (`STATUS-EXPIRED`) - Time limit reached

## System Architecture

### Core Components

1. **Marketplace Listings**: Complete listing data with pricing, timing, and bid tracking
2. **Rich Metadata**: Detailed NFT information including images, descriptions, and attributes  
3. **User Management**: Profiles, verification status, and trading history
4. **Auction System**: Bid management with automatic refunds and finalization
5. **Collection Analytics**: Real-time statistics for NFT collections
6. **Fee Distribution**: Automated marketplace and royalty payments

### Security & Validation

- Comprehensive input validation for all parameters
- Role-based access control for administrative functions
- Secure bid escrow with automatic refunds
- Anti-manipulation measures for auctions
- Price validation with configurable limits
- Principal validation to prevent invalid addresses

## Installation & Setup

### Prerequisites
- Stacks CLI installed
- Clarity development environment
- STX tokens for deployment and trading

### Deployment
```bash
# Deploy to local testnet
stacks deploy contracts/nft-marketplace.clar

# Deploy to Stacks mainnet  
stacks deploy contracts/nft-marketplace.clar --network mainnet
```

### Initial Configuration
```clarity
;; Set marketplace fee rate (2.5% = 250 basis points)
(contract-call? .nft-marketplace set-marketplace-fee-rate u250)

;; Set default royalty rate (5% = 500 basis points)
(contract-call? .nft-marketplace set-royalty-fee-rate u500)

;; Verify trusted creators
(contract-call? .nft-marketplace verify-user 'SP123...CREATOR)
```

## Usage Examples

### Creating Fixed Price Listing

```clarity
(contract-call? .nft-marketplace create-listing
  'SP456...NFT-CONTRACT        ;; NFT contract address
  u1                           ;; Token ID
  u1                           ;; CATEGORY-ART
  u1                           ;; TYPE-FIXED-PRICE
  u50000000                    ;; 50 STX price (50M microSTX)
  u0                           ;; No reserve price for fixed listing
  u4032                        ;; 4 weeks duration
  "Amazing Digital Art"        ;; title
  "A stunning piece of digital art created by AI" ;; description
  "https://ipfs.io/QmX1Y2..."  ;; image URL
  "https://mysite.com/nft/1"   ;; external URL
  "trait_type:Color,value:Blue,trait_type:Rarity,value:Epic" ;; attributes
)
```

### Creating Auction Listing

```clarity
(contract-call? .nft-marketplace create-listing
  'SP789...NFT-CONTRACT        ;; NFT contract address
  u5                           ;; Token ID
  u2                           ;; CATEGORY-COLLECTIBLE  
  u2                           ;; TYPE-AUCTION
  u100000000                   ;; 100 STX starting price
  u10000000                    ;; 10 STX reserve price
  u1008                        ;; 7 days auction duration
  "Rare Collectible #5"        ;; title
  "Limited edition collectible with unique traits" ;; description
  "https://ipfs.io/QmZ3A4..."  ;; image URL
  "https://collection.com/5"   ;; external URL
  "trait_type:Edition,value:Limited,trait_type:Number,value:5" ;; attributes
)
```

### Purchasing NFTs

```clarity
;; Buy fixed price listing immediately
(contract-call? .nft-marketplace buy-now u1)

;; Place bid on auction
(contract-call? .nft-marketplace place-bid u2 u75000000) ;; 75 STX bid

;; Finalize ended auction
(contract-call? .nft-marketplace finalize-auction u2)
```

### Managing Listings

```clarity
;; Update fixed price listing
(contract-call? .nft-marketplace update-listing-price u1 u45000000) ;; 45 STX

;; Cancel active listing
(contract-call? .nft-marketplace cancel-listing u1)
```

### Creating User Profile

```clarity
(contract-call? .nft-marketplace create-user-profile
  "CryptoArtist"               ;; username
  "Digital artist creating unique NFTs on Stacks" ;; bio
  "https://avatar.com/me.jpg"  ;; avatar URL
)
```

## Marketplace Economics

### Fee Structure
- **Marketplace Fee**: Configurable percentage (default 2.5%)
- **Royalty Fee**: Configurable creator royalties (default 5%)
- **Minimum Prices**: 1 STX minimum listing price
- **Bid Increments**: 0.1 STX minimum bid increases

### Revenue Distribution
1. Buyer pays full sale price
2. Marketplace fee deducted and sent to marketplace owner
3. Royalty fee sent to original NFT creator
4. Remaining amount sent to seller
5. All transactions recorded for analytics

### Dutch Auction Mechanics
- Starts at maximum price, decreases linearly over time
- Reaches reserve price at auction end
- Current price calculated: `start_price - ((start_price - reserve_price) * time_elapsed / total_duration)`
- Can be purchased at any time during price decline

## Collection Analytics

### Real-Time Statistics
- **Floor Price**: Lowest current listing price
- **Total Volume**: All-time trading volume
- **Average Price**: Mean sale price across all transactions
- **Total Sales**: Number of completed transactions
- **Last Sale**: Most recent transaction price

### Market Insights
```clarity
;; Get collection statistics
(contract-call? .nft-marketplace get-collection-stats 'SP123...COLLECTION)

;; Get current listing price (handles all listing types)
(contract-call? .nft-marketplace get-current-price u1)

;; Calculate fees for a given price
(contract-call? .nft-marketplace calculate-fees u50000000)
```

## Query Functions

### Listing Information
```clarity
;; Get complete listing details
(contract-call? .nft-marketplace get-marketplace-listing u1)

;; Get listing metadata
(contract-call? .nft-marketplace get-listing-metadata u1)

;; Check if listing is active
(contract-call? .nft-marketplace is-listing-valid u1)

;; Get current dynamic price
(contract-call? .nft-marketplace get-current-price u1)
```

### User & Collection Data
```clarity
;; Get user's listings and activity
(contract-call? .nft-marketplace get-user-listings 'SP123...USER)

;; Get user profile information
(contract-call? .nft-marketplace get-user-profile 'SP123...USER)

;; Get NFT's listing history
(contract-call? .nft-marketplace get-nft-listings 'SP456...CONTRACT u1)

;; Get collection analytics
(contract-call? .nft-marketplace get-collection-stats 'SP789...COLLECTION)
```

### Marketplace Metrics
```clarity
;; Get total marketplace volume
(contract-call? .nft-marketplace get-total-volume)

;; Get current fee rates
(contract-call? .nft-marketplace get-marketplace-fee-rate)

;; Get next listing ID
(contract-call? .nft-marketplace get-next-listing-id)
```

## Administrative Functions

### Fee Management
```clarity
;; Update marketplace fee rate (admin only)
(contract-call? .nft-marketplace set-marketplace-fee-rate u300) ;; 3%

;; Update default royalty rate (admin only)  
(contract-call? .nft-marketplace set-royalty-fee-rate u750) ;; 7.5%
```

### User Management
```clarity
;; Verify user account (admin only)
(contract-call? .nft-marketplace verify-user 'SP123...USER)

;; Transfer admin role
(contract-call? .nft-marketplace set-marketplace-admin 'SP456...NEW-ADMIN)
```

### Emergency Controls
```clarity
;; Emergency cancel listing (admin only)
(contract-call? .nft-marketplace emergency-cancel-listing u1)
```

## Economic Model

### Revenue Streams
- **Transaction Fees**: Percentage of each sale
- **Listing Fees**: Optional fees for premium listings (future enhancement)
- **Verification Fees**: Optional creator verification fees (future enhancement)

### Market Incentives
- **Creator Royalties**: Ongoing revenue for original creators
- **Fee Reduction**: Potential volume-based fee discounts (future enhancement)
- **Staking Rewards**: Marketplace token staking for fee discounts (future enhancement)

## Security Features

- **Escrow System**: Secure bid holding with automatic refunds
- **Access Control**: Role-based permissions for administrative functions
- **Input Validation**: Comprehensive parameter checking and sanitization
- **Reentrancy Protection**: Safe external contract interactions
- **Time Lock Validation**: Proper auction timing enforcement
- **Emergency Controls**: Administrative override capabilities

## Integration Examples

### Frontend Integration
```javascript
// Create listing
const listingTx = await openContractCall({
  contractAddress: 'SP123...CONTRACT',
  contractName: 'nft-marketplace', 
  functionName: 'create-listing',
  functionArgs: [
    contractPrincipalCV('SP456...NFT-CONTRACT'),
    uintCV(1), // token ID
    uintCV(1), // category
    uintCV(1), // listing type
    uintCV(50000000), // price
    uintCV(0), // reserve price
    uintCV(4032), // duration
    stringAsciiCV("Amazing Art"),
    stringAsciiCV("Description"),
    stringAsciiCV("https://image.url"),
    stringAsciiCV("https://external.url"),
    stringAsciiCV("attributes")
  ]
});
```

### API Integration
```javascript
// Get marketplace data
const getListingData = async (listingId) => {
  const response = await fetch(`/api/listings/${listingId}`);
  return response.json();
};

// Get collection stats
const getCollectionStats = async (contractAddress) => {
  const response = await fetch(`/api/collections/${contractAddress}/stats`);
  return response.json();
};
```

## Error Handling

The contract includes comprehensive error codes:

- `ERR-UNAUTHORIZED-ACCESS` (u100): Permission denied
- `ERR-INVALID-LISTING-ID` (u101): Invalid listing ID
- `ERR-LISTING-NOT-FOUND` (u102): Listing doesn't exist
- `ERR-LISTING-EXPIRED` (u103): Listing time expired
- `ERR-INSUFFICIENT-PAYMENT` (u104): Payment amount too low
- `ERR-BID-TOO-LOW` (u112): Bid below minimum increment
- `ERR-AUCTION-ENDED` (u115): Auction voting period ended
- `ERR-NOT-NFT-OWNER` (u116): Not authorized NFT owner

## Future Enhancements

### Planned Features
- **Multi-token Support**: Accept various SIP-010 tokens as payment
- **Batch Operations**: Create/cancel multiple listings at once  
- **Offer System**: Allow direct offers on unlisted NFTs
- **Rental Market**: Time-based NFT usage rights
- **Fractionalization**: Split NFT ownership into tradeable shares
- **Cross-chain Bridge**: Enable trading across different blockchains

### Advanced Features
- **AI-Powered Pricing**: Machine learning price suggestions
- **Social Features**: Following, favorites, and social trading
- **Governance Token**: Marketplace governance and fee reduction
- **Staking Rewards**: Earn rewards for marketplace participation
- **Advanced Analytics**: Detailed market analysis and reporting

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add comprehensive tests
4. Submit a pull request with detailed description
5. Ensure all CI/CD checks pass

## Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)
- [NFT Standards (SIP-009)](https://github.com/stacksgov/sips/blob/main/sips/sip-009/sip-009-nft-standard.md)
- [Marketplace Best Practices](https://docs.stacks.co/clarity/security/)
