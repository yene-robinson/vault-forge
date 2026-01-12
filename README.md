# VaultForge Protocol

> Revolutionary decentralized lending infrastructure powering the next generation of DeFi on Stacks

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Stacks](https://img.shields.io/badge/Built%20on-Stacks-663399)](https://stacks.co/)
[![Clarity](https://img.shields.io/badge/Smart%20Contract-Clarity-blue)](https://clarity-lang.org/)

## Overview

VaultForge is a sophisticated multi-asset collateral protocol that enables users to mint synthetic USDx stablecoins against STX and xBTC collateral. Built on the Stacks blockchain, it bridges Bitcoin's security with DeFi innovation through intelligent risk management and automated liquidation mechanisms.

## Key Features

- **Multi-Asset Collateral Support**: STX and xBTC as collateral assets
- **Synthetic Asset Generation**: SIP-010 compliant USDx stablecoin minting
- **Automated Risk Management**: Dynamic liquidation system with health factor monitoring
- **Real-Time Oracle Integration**: Price feeds with confidence intervals and staleness protection
- **Flexible Vault Management**: Instant collateral adjustments and debt management
- **Permissionless Liquidations**: Economic incentives for system stability maintenance

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        VaultForge Protocol                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────── │
│  │   Oracle Layer  │    │  Vault Engine   │    │  Liquidation  │
│  │                 │    │                 │    │   Engine      │
│  │ • Price Feeds   │◄──►│ • Collateral    │◄──►│ • Health      │
│  │ • Confidence    │    │   Management    │    │   Monitoring  │
│  │ • Staleness     │    │ • Debt Tracking │    │ • Automated   │
│  │   Protection    │    │ • Risk Calc     │    │   Execution   │
│  └─────────────────┘    └─────────────────┘    └─────────────── │
│           │                       │                       │     │
│           ▼                       ▼                       ▼     │
│  ┌─────────────────────────────────────────────────────────────┤
│  │                    USDx Token Layer                        │
│  │                                                             │
│  │ • SIP-010 Compliance    • Mint/Burn Operations             │
│  │ • Balance Management    • Transfer Functions               │
│  └─────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┤
│  │                  Collateral Management                      │
│  │                                                             │
│  │ • STX Deposits/Withdrawals  • xBTC Integration             │
│  │ • Multi-Asset Support       • Ratio Calculations           │
│  └─────────────────────────────────────────────────────────────┤
└─────────────────────────────────────────────────────────────────┘
```

## Contract Architecture

### Core Components

#### 1. **Vault Management System**

- **Vault Creation**: Multi-collateral vault initialization
- **Collateral Operations**: Deposit, withdrawal, and adjustment functions
- **Debt Management**: USDx minting and burning operations
- **State Tracking**: Comprehensive vault state management

#### 2. **Oracle Price Feed System**

- **Multi-Asset Pricing**: STX and xBTC price feeds
- **Confidence Intervals**: Price reliability metrics
- **Staleness Protection**: Time-based price validation
- **Operator Management**: Authorized oracle operator system

#### 3. **Risk Management Engine**

- **Health Factor Calculation**: Real-time collateralization ratios
- **Liquidation Threshold**: 150% liquidation ratio
- **Minimum Collateral**: 200% minimum for new positions
- **Dynamic Risk Assessment**: Continuous monitoring system

#### 4. **Liquidation Engine**

- **Automated Liquidations**: Undercollateralized vault processing
- **Liquidation Incentives**: 10% penalty structure
- **Permissionless Execution**: Open liquidator participation
- **Collateral Distribution**: Efficient asset reallocation

### Data Flow

```
User Interaction Flow:
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Deposit   │───►│   Create    │───►│    Mint     │───►│   Manage    │
│ Collateral  │    │   Vault     │    │   USDx      │    │   Position  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │                   │
       ▼                   ▼                   ▼                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     Protocol State Updates                          │
│ • Collateral Tracking  • Debt Accounting  • Risk Monitoring        │
└─────────────────────────────────────────────────────────────────────┘

Liquidation Flow:
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Monitor   │───►│   Detect    │───►│  Execute    │───►│ Distribute  │
│ Health Risk │    │ Liquidation │    │ Liquidation │    │ Collateral  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

## System Overview

### Collateral Types

- **STX**: Native Stacks token with dynamic pricing
- **xBTC**: Wrapped Bitcoin with oracle-based valuation

### Risk Parameters

- **Liquidation Ratio**: 150% (liquidation threshold)
- **Minimum Collateral Ratio**: 200% (new vault requirement)
- **Liquidation Penalty**: 10% (liquidator incentive)
- **Stability Fee**: 2% annual (protocol revenue)

### Oracle Integration

- **Price Staleness**: 1-hour maximum age
- **Confidence Scoring**: 1-100% reliability metrics
- **Multi-Operator Support**: Decentralized price feed management

## Technical Specifications

### Smart Contract Standards

- **SIP-010**: Fungible token standard compliance
- **Clarity Language**: Stacks native smart contract language
- **Immutable Logic**: Deterministic execution guarantees

### Security Features

- **Access Control**: Role-based permission system
- **Input Validation**: Comprehensive parameter checking
- **Emergency Controls**: Protocol shutdown capabilities
- **Economic Security**: Aligned incentive structures

## Getting Started

### Prerequisites

- Stacks wallet with STX tokens
- Understanding of DeFi collateral systems
- Basic knowledge of smart contract interactions

### Key Functions

#### Vault Operations

```clarity
;; Create a new vault
(create-vault stx-amount xbtc-amount)

;; Add collateral to existing vault
(add-collateral vault-id stx-amount xbtc-amount)

;; Mint USDx against collateral
(mint-usdx vault-id amount)

;; Burn USDx to reduce debt
(burn-usdx vault-id amount)

;; Withdraw collateral
(withdraw-collateral vault-id stx-amount)
```

#### Monitoring Functions

```clarity
;; Check vault health
(calculate-health-factor vault-id)

;; Get vault details
(get-vault vault-id)

;; View protocol statistics
(get-protocol-stats)
```

## Risk Management

### For Users

- **Maintain Healthy Ratios**: Keep collateralization above 200%
- **Monitor Market Conditions**: Watch for price volatility
- **Regular Position Management**: Adjust collateral as needed
- **Emergency Procedures**: Understand liquidation risks

### For Liquidators

- **Capital Requirements**: Hold sufficient USDx for liquidations
- **Risk Assessment**: Evaluate liquidation opportunities
- **Economic Incentives**: 10% penalty reward structure
- **System Stability**: Contribute to protocol health

## Governance

### Protocol Parameters

- **Owner Controls**: Emergency shutdown capabilities
- **Parameter Updates**: Liquidation ratio adjustments
- **Operator Management**: Oracle and liquidator authorization
- **System Upgrades**: Protocol evolution mechanisms

## Contributing

We welcome contributions to VaultForge Protocol. Please ensure all code follows our security standards and includes comprehensive testing.

## Security Considerations

- **Smart Contract Audits**: Regular security reviews
- **Economic Attack Vectors**: Comprehensive threat modeling
- **Oracle Dependencies**: Price feed reliability requirements
- **Liquidation Risks**: System solvency protection

## License

This project is licensed under the MIT License - see the LICENSE file for details.
