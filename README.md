# OrangeSwap Protocol

[![Clarity Version](https://img.shields.io/badge/Clarity-2.0-orange.svg)](https://clarity-lang.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/Build-Passing-green.svg)](https://github.com/david-u128/orange-swap)

> A next-generation automated market maker built exclusively for the Bitcoin ecosystem on Stacks Layer 2. OrangeSwap brings institutional-grade DeFi primitives to Bitcoin holders, enabling trustless asset exchanges with capital efficiency and minimal slippage.

## 🍊 Overview

OrangeSwap is a sophisticated decentralized exchange (DEX) protocol that implements a constant product market maker (x*y=k) algorithm optimized for the Bitcoin ecosystem on Stacks Layer 2. The protocol enables users to swap tokens, provide liquidity, and earn fees through a secure, trustless infrastructure.

### Core Features

- **Constant Product Market Maker**: Implements the proven x*y=k algorithm for reliable price discovery
- **Dynamic Fee Optimization**: Bitcoin-native trading with optimized fee structures
- **Multi-Asset Liquidity Pools**: Support for diverse token pairs with yield farming opportunities
- **MEV Protection**: Built-in front-running resistance mechanisms
- **Gasless Transactions**: Leverages Bitcoin settlement finality for efficient execution
- **Institutional-Grade Security**: Comprehensive validation and slippage protection

## 🏗️ Architecture

### Smart Contract Structure

```
contracts/
├── orange-swap.clar          # Main AMM protocol contract
└── traits/
    └── ft-trait.clar        # Fungible token trait definition
```

### Key Components

1. **Fungible Token Trait**: Standardized interface for SIP-010 compatible tokens
2. **Pool Management**: Creation and management of trading pairs
3. **Liquidity Provision**: Add/remove liquidity with proportional share calculation
4. **Token Swapping**: Secure token exchanges with slippage protection
5. **Administrative Controls**: Protocol governance and emergency functions

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) >= 2.0.0
- [Node.js](https://nodejs.org/) >= 18.0.0
- [Stacks CLI](https://docs.stacks.co/build-on-stacks/command-line-interface)

### Installation

1. Clone the repository:

```bash
git clone https://github.com/david-u128/orange-swap.git
cd orange-swap
```

2. Install dependencies:

```bash
npm install
```

3. Check contract syntax:

```bash
clarinet check
```

4. Run tests:

```bash
npm test
```

### Local Development

Start a local Clarinet environment:

```bash
clarinet integrate
```

Deploy contracts to devnet:

```bash
clarinet deploy --devnet
```

## 📖 Usage

### Creating a Trading Pool

```clarity
;; Create a new trading pair pool (only contract owner)
(contract-call? .orange-swap create-pool .token-a .token-b)
```

### Adding Liquidity

```clarity
;; Add liquidity to earn trading fees
(contract-call? .orange-swap add-liquidity
  u0          ;; pool-id
  .token-a    ;; token-x
  .token-b    ;; token-y
  u1000000    ;; amount-x (1 token with 6 decimals)
  u2000000    ;; amount-y (2 tokens with 6 decimals)
  u1000       ;; min-shares (minimum LP tokens to receive)
)
```

### Swapping Tokens

```clarity
;; Swap tokens with slippage protection
(contract-call? .orange-swap swap-exact-tokens-for-tokens
  u0          ;; pool-id
  .token-a    ;; token-in
  .token-b    ;; token-out
  u500000     ;; amount-in (0.5 tokens)
  u900000     ;; min-amount-out (minimum output)
  true        ;; x-for-y (direction)
)
```

### Removing Liquidity

```clarity
;; Withdraw liquidity and underlying tokens
(contract-call? .orange-swap remove-liquidity
  u0          ;; pool-id
  .token-a    ;; token-x
  .token-b    ;; token-y
  u500        ;; shares to burn
  u450000     ;; min-amount-x
  u900000     ;; min-amount-y
)
```

## 🔍 API Reference

### Public Functions

#### `create-pool`

Creates a new trading pair pool.

- **Parameters**: `token-x`, `token-y` (fungible token contracts)
- **Returns**: `(response uint uint)` - Pool ID on success
- **Access**: Contract owner only

#### `add-liquidity`

Provides liquidity to earn trading fees.

- **Parameters**: `pool-id`, `token-x`, `token-y`, `amount-x`, `amount-y`, `min-shares`
- **Returns**: `(response uint uint)` - LP shares minted
- **Access**: Public

#### `swap-exact-tokens-for-tokens`

Executes token swaps with slippage protection.

- **Parameters**: `pool-id`, `token-in`, `token-out`, `amount-in`, `min-amount-out`, `x-for-y`
- **Returns**: `(response uint uint)` - Output amount
- **Access**: Public

#### `remove-liquidity`

Withdraws liquidity and underlying tokens.

- **Parameters**: `pool-id`, `token-x`, `token-y`, `shares`, `min-amount-x`, `min-amount-y`
- **Returns**: `(response {amount-x: uint, amount-y: uint} uint)`
- **Access**: Public

### Read-Only Functions

#### `get-pool-details`

Returns pool information including reserves and metadata.

- **Parameters**: `pool-id`
- **Returns**: Pool details or none

#### `get-liquidity-position`

Gets liquidity provider's position in a pool.

- **Parameters**: `pool-id`, `provider`
- **Returns**: Provider's shares or none

#### `get-spot-price`

Calculates current spot price for a trading pair.

- **Parameters**: `pool-id`
- **Returns**: `(response uint uint)` - Price ratio

#### `get-protocol-fee`

Returns current protocol fee rate.

- **Returns**: `uint` - Fee rate in basis points

### Administrative Functions

#### `update-protocol-fee`

Updates the protocol fee rate.

- **Parameters**: `new-fee`
- **Access**: Contract owner only

#### `emergency-pause-pool`

Pauses trading for a specific pool.

- **Parameters**: `pool-id`
- **Access**: Contract owner only

#### `resume-pool`

Resumes trading for a paused pool.

- **Parameters**: `pool-id`
- **Access**: Contract owner only

## 🔐 Security

### Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | `ERR-NOT-AUTHORIZED` | Unauthorized access attempt |
| 101 | `ERR-INVALID-AMOUNT` | Invalid amount provided |
| 102 | `ERR-INSUFFICIENT-BALANCE` | Insufficient token balance |
| 103 | `ERR-POOL-NOT-FOUND` | Pool does not exist |
| 104 | `ERR-INVALID-POOL` | Invalid pool configuration |
| 105 | `ERR-SLIPPAGE-TOO-HIGH` | Slippage exceeds tolerance |
| 106 | `ERR-ZERO-LIQUIDITY` | No liquidity available |

### Security Features

- **Slippage Protection**: Minimum output validation for all swaps
- **Overflow Protection**: Safe arithmetic operations
- **Access Controls**: Owner-only administrative functions
- **Pool Validation**: Comprehensive pool state checks
- **Emergency Controls**: Pause/resume functionality

## 🧪 Testing

The protocol includes comprehensive test coverage using Vitest and Clarinet testing framework.

Run the test suite:

```bash
npm test
```

Run contract checks:

```bash
clarinet check
```

### Test Coverage

- Pool creation and management
- Liquidity provision and withdrawal
- Token swapping mechanics
- Slippage protection
- Error handling
- Administrative functions

## 📊 Mathematics

### Constant Product Formula

The protocol uses the constant product market maker formula:

```
x * y = k
```

Where:

- `x` = Reserve of token X
- `y` = Reserve of token Y  
- `k` = Constant product

### Swap Calculation

Output amount calculation with fees:

```clarity
output = (input_with_fee * output_reserve) / (input_reserve * PRECISION + input_with_fee)
```

Where:

- `input_with_fee = input_amount * (PRECISION - protocol_fee)`
- `PRECISION = 1,000,000` (6 decimal places)

### Liquidity Shares

For initial liquidity provision:

```clarity
shares = sqrt(amount_x * amount_y)
```

For subsequent additions:

```clarity
shares = min(
  (amount_x * total_shares) / reserve_x,
  (amount_y * total_shares) / reserve_y
)
```

## 🤝 Contributing

We welcome contributions to the OrangeSwap protocol! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Run tests: `npm test`
4. Commit changes: `git commit -am 'Add feature'`
5. Push to branch: `git push origin feature-name`
6. Submit a pull request

### Development Guidelines

- Follow Clarity best practices
- Add comprehensive tests for new features
- Update documentation as needed
- Ensure all tests pass before submitting

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://clarity-lang.org/)
- [Clarinet Documentation](https://docs.hiro.so/clarinet)
- [SIP-010 Token Standard](https://github.com/stacksgov/sips/blob/main/sips/sip-010/sip-010-fungible-token-standard.md)
