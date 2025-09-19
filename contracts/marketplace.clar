;; Decentralized NFT Marketplace Smart Contract
;; Manages NFT listings, auctions, trades, and marketplace operations

;; Error Constants
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-INVALID-LISTING-ID (err u101))
(define-constant ERR-LISTING-NOT-FOUND (err u102))
(define-constant ERR-LISTING-EXPIRED (err u103))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u104))
(define-constant ERR-INVALID-PERCENTAGE (err u105))
(define-constant ERR-ALREADY-EXISTS (err u106))
(define-constant ERR-INVALID-DURATION (err u107))
(define-constant ERR-TRANSFER-FAILED (err u108))
(define-constant ERR-INVALID-PRINCIPAL (err u109))
(define-constant ERR-LISTING-NOT-ACTIVE (err u110))
(define-constant ERR-INVALID-NFT-TYPE (err u111))
(define-constant ERR-BID-TOO-LOW (err u112))
(define-constant ERR-LIST-FULL (err u113))
(define-constant ERR-INVALID-INPUT (err u114))
(define-constant ERR-AUCTION-ENDED (err u115))
(define-constant ERR-NOT-NFT-OWNER (err u116))

;; Validation Constants
(define-constant MIN-LISTING-PRICE u1000000) ;; 1 STX in microSTX
(define-constant MAX-LISTING-PRICE u1000000000000) ;; 1M STX max
(define-constant MIN-AUCTION-DURATION u144) ;; ~1 day in blocks
(define-constant MAX-AUCTION_DURATION u4032) ;; ~4 weeks in blocks
(define-constant MIN-BID-INCREMENT u100000) ;; 0.1 STX minimum bid increment

;; Contract Constants
(define-constant marketplace-owner tx-sender)
(define-constant marketplace-name "decentralized-nft-marketplace")

;; Data Variables
(define-data-var next-listing-id uint u1)
(define-data-var marketplace-fee-rate uint u250) ;; 2.5% in basis points
(define-data-var royalty-fee-rate uint u500) ;; 5% default royalty rate
(define-data-var marketplace-admin principal marketplace-owner)
(define-data-var total-volume uint u0)

;; NFT Categories
(define-constant CATEGORY-ART u1)
(define-constant CATEGORY-COLLECTIBLE u2)
(define-constant CATEGORY-GAMING u3)
(define-constant CATEGORY-UTILITY u4)
(define-constant CATEGORY-MUSIC u5)

;; Listing Types
(define-constant TYPE-FIXED-PRICE u1)
(define-constant TYPE-AUCTION u2)
(define-constant TYPE-DUTCH-AUCTION u3)

;; Listing Status
(define-constant STATUS-ACTIVE u1)
(define-constant STATUS-SOLD u2)
(define-constant STATUS-CANCELLED u3)
(define-constant STATUS-EXPIRED u4)

;; Data Maps
(define-map marketplace-listings
  { listing-id: uint }
  {
    seller: principal,
    nft-contract: principal,
    token-id: uint,
    category: uint,
    listing-type: uint,
    price: uint,
    reserve-price: uint,
    current-bid: uint,
    highest-bidder: (optional principal),
    created-at: uint,
    expires-at: uint,
    status: uint,
    bid-count: uint,
    views: uint
  }
)

(define-map listing-metadata
  { listing-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    image-url: (string-ascii 200),
    external-url: (string-ascii 200),
    attributes: (string-ascii 1000)
  }
)

(define-map nft-listings
  { nft-contract: principal, token-id: uint }
  { active-listing-id: (optional uint), listing-history: (list 20 uint) }
)

(define-map user-listings
  { user: principal }
  { active-listings: (list 50 uint), sold-listings: (list 100 uint), bid-listings: (list 100 uint) }
)

(define-map auction-bids
  { listing-id: uint, bid-id: uint }
  {
    bidder: principal,
    amount: uint,
    timestamp: uint,
    is-winning: bool
  }
)

(define-map collection-stats
  { collection: principal }
  {
    total-volume: uint,
    floor-price: uint,
    total-sales: uint,
    average-price: uint,
    last-sale: uint
  }
)

(define-map user-profiles
  { user: principal }
  {
    username: (string-ascii 50),
    bio: (string-ascii 200),
    avatar-url: (string-ascii 200),
    verified: bool,
    total-sales: uint,
    total-purchases: uint
  }
)

;; Private Functions

(define-private (is-marketplace-admin (user principal))
  (is-eq user (var-get marketplace-admin))
)

(define-private (is-valid-category (category uint))
  (and (>= category CATEGORY-ART) (<= category CATEGORY-MUSIC))
)

(define-private (is-valid-listing-type (listing-type uint))
  (and (>= listing-type TYPE-FIXED-PRICE) (<= listing-type TYPE-DUTCH-AUCTION))
)

(define-private (is-valid-price (price uint))
  (and (>= price MIN-LISTING-PRICE) (<= price MAX-LISTING-PRICE))
)

(define-private (is-valid-duration (duration uint))
  (and (>= duration MIN-AUCTION-DURATION) (<= duration MAX-AUCTION_DURATION))
)

(define-private (is-valid-percentage (percentage uint))
  (<= percentage u10000)
)

(define-private (is-valid-string-ascii-50 (input (string-ascii 50)))
  (> (len input) u0)
)

(define-private (is-valid-string-ascii-100 (input (string-ascii 100)))
  (> (len input) u0)
)

(define-private (is-valid-string-ascii-200 (input (string-ascii 200)))
  (> (len input) u0)
)

(define-private (is-valid-string-ascii-500 (input (string-ascii 500)))
  (> (len input) u0)
)

(define-private (is-valid-string-ascii-1000 (input (string-ascii 1000)))
  (> (len input) u0)
)

(define-private (is-valid-listing-id (listing-id uint))
  (and (> listing-id u0) (< listing-id (var-get next-listing-id)))
)

(define-private (is-valid-principal (user principal))
  (not (is-eq user 'SP000000000000000000002Q6VF78))
)

(define-private (get-current-block)
  block-height
)

(define-private (is-listing-active (listing-data (optional {seller: principal, nft-contract: principal, token-id: uint, category: uint, listing-type: uint, price: uint, reserve-price: uint, current-bid: uint, highest-bidder: (optional principal), created-at: uint, expires-at: uint, status: uint, bid-count: uint, views: uint})))
  (match listing-data
    listing (and 
              (is-eq (get status listing) STATUS-ACTIVE)
              (> (get expires-at listing) (get-current-block)))
    false
  )
)

(define-private (calculate-marketplace-fee (amount uint))
  (/ (* amount (var-get marketplace-fee-rate)) u10000)
)

(define-private (calculate-royalty-fee (amount uint))
  (/ (* amount (var-get royalty-fee-rate)) u10000)
)

(define-private (calculate-dutch-auction-price (listing-data {seller: principal, nft-contract: principal, token-id: uint, category: uint, listing-type: uint, price: uint, reserve-price: uint, current-bid: uint, highest-bidder: (optional principal), created-at: uint, expires-at: uint, status: uint, bid-count: uint, views: uint}))
  (let ((time-elapsed (- (get-current-block) (get created-at listing-data)))
        (total-duration (- (get expires-at listing-data) (get created-at listing-data)))
        (price-drop (- (get price listing-data) (get reserve-price listing-data))))
    (if (>= time-elapsed total-duration)
      (get reserve-price listing-data)
      (- (get price listing-data) (/ (* price-drop time-elapsed) total-duration))
    )
  )
)

(define-private (add-listing-to-nft (nft-contract principal) (token-id uint) (listing-id uint))
  (let ((current-data (default-to { active-listing-id: none, listing-history: (list) }
                                 (map-get? nft-listings { nft-contract: nft-contract, token-id: token-id }))))
    (match (as-max-len? (append (get listing-history current-data) listing-id) u20)
      updated-history (begin
                        (map-set nft-listings 
                                 { nft-contract: nft-contract, token-id: token-id }
                                 { active-listing-id: (some listing-id), listing-history: updated-history })
                        (ok true))
      ERR-LIST-FULL
    )
  )
)

(define-private (add-listing-to-user (user principal) (listing-id uint) (is-seller bool))
  (let ((current-data (default-to { active-listings: (list), sold-listings: (list), bid-listings: (list) }
                                 (map-get? user-listings { user: user }))))
    (if is-seller
      (match (as-max-len? (append (get active-listings current-data) listing-id) u50)
        updated-active (begin
                         (map-set user-listings 
                                  { user: user }
                                  (merge current-data { active-listings: updated-active }))
                         (ok true))
        ERR-LIST-FULL)
      (match (as-max-len? (append (get bid-listings current-data) listing-id) u100)
        updated-bids (begin
                       (map-set user-listings 
                                { user: user }
                                (merge current-data { bid-listings: updated-bids }))
                       (ok true))
        ERR-LIST-FULL)
    )
  )
)

(define-private (update-collection-stats (collection principal) (sale-price uint))
  (let ((current-stats (default-to { total-volume: u0, floor-price: sale-price, total-sales: u0, average-price: u0, last-sale: u0 }
                                  (map-get? collection-stats { collection: collection }))))
    (let ((new-total-volume (+ (get total-volume current-stats) sale-price))
          (new-total-sales (+ (get total-sales current-stats) u1))
          (new-average-price (/ new-total-volume new-total-sales))
          (new-floor-price (if (< sale-price (get floor-price current-stats)) sale-price (get floor-price current-stats))))
      
      (map-set collection-stats
               { collection: collection }
               {
                 total-volume: new-total-volume,
                 floor-price: new-floor-price,
                 total-sales: new-total-sales,
                 average-price: new-average-price,
                 last-sale: sale-price
               })
      (ok true)
    )
  )
)

;; Read-only Functions

(define-read-only (get-marketplace-listing (listing-id uint))
  (map-get? marketplace-listings { listing-id: listing-id })
)

(define-read-only (get-listing-metadata (listing-id uint))
  (map-get? listing-metadata { listing-id: listing-id })
)

(define-read-only (get-nft-listings (nft-contract principal) (token-id uint))
  (map-get? nft-listings { nft-contract: nft-contract, token-id: token-id })
)

(define-read-only (get-user-listings (user principal))
  (map-get? user-listings { user: user })
)

(define-read-only (get-collection-stats (collection principal))
  (map-get? collection-stats { collection: collection })
)

(define-read-only (get-user-profile (user principal))
  (map-get? user-profiles { user: user })
)

(define-read-only (get-marketplace-fee-rate)
  (var-get marketplace-fee-rate)
)

(define-read-only (get-total-volume)
  (var-get total-volume)
)

(define-read-only (get-next-listing-id)
  (var-get next-listing-id)
)

(define-read-only (is-listing-valid (listing-id uint))
  (let ((listing-data (get-marketplace-listing listing-id)))
    (is-listing-active listing-data)
  )
)

(define-read-only (get-current-price (listing-id uint))
  (match (get-marketplace-listing listing-id)
    listing-data (ok 
      (if (is-eq (get listing-type listing-data) TYPE-DUTCH-AUCTION)
        (calculate-dutch-auction-price listing-data)
        (if (is-eq (get listing-type listing-data) TYPE-AUCTION)
          (get current-bid listing-data)
          (get price listing-data)
        )
      )
    )
    ERR-LISTING-NOT-FOUND
  )
)

(define-read-only (calculate-fees (sale-price uint))
  (ok {
    marketplace-fee: (calculate-marketplace-fee sale-price),
    royalty-fee: (calculate-royalty-fee sale-price),
    seller-amount: (- sale-price (+ (calculate-marketplace-fee sale-price) (calculate-royalty-fee sale-price)))
  })
)

;; Public Functions

(define-public (create-listing 
                (nft-contract principal)
                (token-id uint)
                (category uint)
                (listing-type uint)
                (price uint)
                (reserve-price uint)
                (duration uint)
                (title (string-ascii 100))
                (description (string-ascii 500))
                (image-url (string-ascii 200))
                (external-url (string-ascii 200))
                (attributes (string-ascii 1000)))
  (let ((listing-id (var-get next-listing-id))
        (current-block (get-current-block))
        (expires-at (+ current-block duration)))
    
    ;; Input validation
    (asserts! (is-valid-string-ascii-100 title) ERR-INVALID-INPUT)
    (asserts! (is-valid-string-ascii-500 description) ERR-INVALID-INPUT)
    (asserts! (is-valid-string-ascii-200 image-url) ERR-INVALID-INPUT)
    (asserts! (is-valid-string-ascii-200 external-url) ERR-INVALID-INPUT)
    (asserts! (is-valid-string-ascii-1000 attributes) ERR-INVALID-INPUT)
    
    ;; Business logic validation
    (asserts! (is-valid-category category) ERR-INVALID-NFT-TYPE)
    (asserts! (is-valid-listing-type listing-type) ERR-INVALID-INPUT)
    (asserts! (is-valid-price price) ERR-INVALID-INPUT)
    (asserts! (is-valid-duration duration) ERR-INVALID-DURATION)
    (asserts! (is-valid-principal nft-contract) ERR-INVALID-PRINCIPAL)
    
    ;; Validate reserve price for auctions
    (if (or (is-eq listing-type TYPE-AUCTION) (is-eq listing-type TYPE-DUTCH-AUCTION))
      (asserts! (and (> reserve-price u0) (<= reserve-price price)) ERR-INVALID-INPUT)
      true
    )
    
    ;; Create listing record
    (map-set marketplace-listings
             { listing-id: listing-id }
             {
               seller: tx-sender,
               nft-contract: nft-contract,
               token-id: token-id,
               category: category,
               listing-type: listing-type,
               price: price,
               reserve-price: reserve-price,
               current-bid: u0,
               highest-bidder: none,
               created-at: current-block,
               expires-at: expires-at,
               status: STATUS-ACTIVE,
               bid-count: u0,
               views: u0
             })
    
    ;; Set metadata
    (map-set listing-metadata
             { listing-id: listing-id }
             {
               title: title,
               description: description,
               image-url: image-url,
               external-url: external-url,
               attributes: attributes
             })
    
    ;; Update indexes
    (try! (add-listing-to-nft nft-contract token-id listing-id))
    (try! (add-listing-to-user tx-sender listing-id true))
    
    ;; Increment listing ID counter
    (var-set next-listing-id (+ listing-id u1))
    
    (ok listing-id)
  )
)
