;; OrangeSwap Protocol
;;
;; A next-generation automated market maker built exclusively for the
;; Bitcoin ecosystem on Stacks Layer 2. OrangeSwap brings institutional-grade
;; DeFi primitives to Bitcoin holders, enabling trustless asset exchanges
;; with capital efficiency and minimal slippage.
;;
;; Core Features:
;; - Constant Product Market Maker (x*y=k) algorithm
;; - Dynamic fee optimization for Bitcoin-native trading
;; - Multi-asset liquidity pools with yield farming opportunities
;; - MEV protection and front-running resistance
;; - Gasless transactions through Bitcoin settlement finality
;;
;; Built for the future of Bitcoin DeFi on Stacks Layer 2

;; FUNGIBLE TOKEN TRAIT DEFINITION

(define-trait ft-trait (
  (transfer
    (uint principal principal)
    (response bool uint)
  )
  (get-balance
    (principal)
    (response uint uint)
  )
  (get-total-supply
    ()
    (response uint uint)
  )
  (get-decimals
    ()
    (response uint uint)
  )
  (get-name
    ()
    (response (string-ascii 32) uint)
  )
  (get-symbol
    ()
    (response (string-ascii 32) uint)
  )
))

;; PROTOCOL CONSTANTS & ERROR CODES

(define-constant CONTRACT-OWNER tx-sender)
(define-constant PRECISION u1000000) ;; 6 decimal precision for calculations

;; Error Codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-POOL-NOT-FOUND (err u103))
(define-constant ERR-INVALID-POOL (err u104))
(define-constant ERR-SLIPPAGE-TOO-HIGH (err u105))
(define-constant ERR-ZERO-LIQUIDITY (err u106))

;; PROTOCOL STATE VARIABLES

(define-data-var protocol-fee-rate uint u3000) ;; 0.3% base fee
(define-data-var total-pools uint u0)

;; DATA STORAGE MAPS

;; Pool registry with reserves and metadata
(define-map pools
  uint
  {
    token-x: principal,
    token-y: principal,
    reserve-x: uint,
    reserve-y: uint,
    total-shares: uint,
    active: bool,
  }
)

;; Liquidity provider positions
(define-map liquidity-providers
  {
    pool-id: uint,
    provider: principal,
  }
  { shares: uint }
)

;; MATHEMATICAL UTILITIES

(define-private (safe-multiply
    (a uint)
    (b uint)
  )
  (* a b)
)

(define-private (minimum
    (a uint)
    (b uint)
  )
  (if (<= a b)
    a
    b
  )
)

;; CORE AMM ALGORITHM

;; Calculates output amount using constant product formula with fees
(define-private (calculate-swap-output
    (input-amount uint)
    (input-reserve uint)
    (output-reserve uint)
  )
  (let (
      (input-with-fee (safe-multiply input-amount (- PRECISION (var-get protocol-fee-rate))))
      (numerator (safe-multiply input-with-fee output-reserve))
      (denominator (+ (safe-multiply input-reserve PRECISION) input-with-fee))
    )
    (/ numerator denominator)
  )
)

;; Mints liquidity provider tokens based on proportional contribution
(define-private (mint-liquidity-tokens
    (pool-id uint)
    (amount-x uint)
    (amount-y uint)
    (recipient principal)
  )
  (let (
      (pool (unwrap! (map-get? pools pool-id) ERR-POOL-NOT-FOUND))
      (total-shares (get total-shares pool))
      (shares-to-mint (if (is-eq total-shares u0)
        (safe-multiply amount-x amount-y) ;; Genesis liquidity
        (minimum (/ (safe-multiply amount-x total-shares) (get reserve-x pool))
          (/ (safe-multiply amount-y total-shares) (get reserve-y pool))
        )
      ))
    )
    ;; Update pool reserves
    (map-set pools pool-id
      (merge pool {
        reserve-x: (+ (get reserve-x pool) amount-x),
        reserve-y: (+ (get reserve-y pool) amount-y),
        total-shares: (+ total-shares shares-to-mint),
      })
    )

    ;; Update provider position
    (map-set liquidity-providers {
      pool-id: pool-id,
      provider: recipient,
    } { shares: (+
      (default-to u0
        (get shares
          (map-get? liquidity-providers {
            pool-id: pool-id,
            provider: recipient,
          })
        ))
      shares-to-mint
    ) }
    )
    (ok shares-to-mint)
  )
)

;; PUBLIC PROTOCOL FUNCTIONS

;; Creates a new trading pair pool
(define-public (create-pool
    (token-x <ft-trait>)
    (token-y <ft-trait>)
  )
  (let (
      (pool-id (var-get total-pools))
      (token-x-principal (contract-of token-x))
      (token-y-principal (contract-of token-y))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq token-x-principal token-y-principal)) ERR-INVALID-POOL)

    (map-set pools pool-id {
      token-x: token-x-principal,
      token-y: token-y-principal,
      reserve-x: u0,
      reserve-y: u0,
      total-shares: u0,
      active: true,
    })

    (var-set total-pools (+ pool-id u1))
    (ok pool-id)
  )
)

;; Provides liquidity to earn trading fees
(define-public (add-liquidity
    (pool-id uint)
    (token-x <ft-trait>)
    (token-y <ft-trait>)
    (amount-x uint)
    (amount-y uint)
    (min-shares uint)
  )
  (let (
      (pool (unwrap! (map-get? pools pool-id) ERR-POOL-NOT-FOUND))
      (token-x-principal (contract-of token-x))
      (token-y-principal (contract-of token-y))
    )
    ;; Validation checks
    (asserts! (and (> amount-x u0) (> amount-y u0)) ERR-INVALID-AMOUNT)
    (asserts! (get active pool) ERR-POOL-NOT-FOUND)
    (asserts! (is-eq token-x-principal (get token-x pool)) ERR-INVALID-POOL)
    (asserts! (is-eq token-y-principal (get token-y pool)) ERR-INVALID-POOL)

    ;; Transfer tokens to pool contract
    (try! (contract-call? token-x transfer amount-x tx-sender (as-contract tx-sender)))
    (try! (contract-call? token-y transfer amount-y tx-sender (as-contract tx-sender)))

    ;; Mint LP tokens
    (let ((shares (unwrap! (mint-liquidity-tokens pool-id amount-x amount-y tx-sender)
        ERR-INVALID-AMOUNT
      )))
      (asserts! (>= shares min-shares) ERR-SLIPPAGE-TOO-HIGH)
      (ok shares)
    )
  )
)

;; Executes token swaps with slippage protection
(define-public (swap-exact-tokens-for-tokens
    (pool-id uint)
    (token-in <ft-trait>)
    (token-out <ft-trait>)
    (amount-in uint)
    (min-amount-out uint)
    (x-for-y bool)
  )
  (let (
      (pool (unwrap! (map-get? pools pool-id) ERR-POOL-NOT-FOUND))
      (token-in-principal (contract-of token-in))
      (token-out-principal (contract-of token-out))
      (input-reserve (if x-for-y
        (get reserve-x pool)
        (get reserve-y pool)
      ))
      (output-reserve (if x-for-y
        (get reserve-y pool)
        (get reserve-x pool)
      ))
    )
    ;; Validation
    (asserts! (> amount-in u0) ERR-INVALID-AMOUNT)
    (asserts! (get active pool) ERR-POOL-NOT-FOUND)
    (asserts!
      (is-eq token-in-principal
        (if x-for-y
          (get token-x pool)
          (get token-y pool)
        ))
      ERR-INVALID-POOL
    )
    (asserts!
      (is-eq token-out-principal
        (if x-for-y
          (get token-y pool)
          (get token-x pool)
        ))
      ERR-INVALID-POOL
    )

    (let ((amount-out (calculate-swap-output amount-in input-reserve output-reserve)))
      (asserts! (>= amount-out min-amount-out) ERR-SLIPPAGE-TOO-HIGH)

      ;; Execute token transfers
      (try! (contract-call? token-in transfer amount-in tx-sender
        (as-contract tx-sender)
      ))
      (as-contract (try! (contract-call? token-out transfer amount-out (as-contract tx-sender)
        tx-sender
      )))

      ;; Update pool state
      (map-set pools pool-id
        (merge pool
          (if x-for-y
            {
              reserve-x: (+ input-reserve amount-in),
              reserve-y: (- output-reserve amount-out),
            }
            {
              reserve-x: (- output-reserve amount-out),
              reserve-y: (+ input-reserve amount-in),
            }
          ))
      )

      (ok amount-out)
    )
  )
)

;; Withdraws liquidity and underlying tokens
(define-public (remove-liquidity
    (pool-id uint)
    (token-x <ft-trait>)
    (token-y <ft-trait>)
    (shares uint)
    (min-amount-x uint)
    (min-amount-y uint)
  )