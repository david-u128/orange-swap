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