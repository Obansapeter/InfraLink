# InfraLink Smart Contract

A decentralized infrastructure staking protocol built on Stacks blockchain that enables node operators to stake STX tokens and earn rewards for providing reliable infrastructure services.

## Overview

InfraLink creates an incentivized network of infrastructure providers who stake STX tokens as collateral and earn daily rewards for maintaining active services. The protocol includes an oracle-based verification system and a cooldown mechanism for secure unstaking.

## Features

- **Node Registration**: Infrastructure providers can register as network nodes
- **STX Staking**: Secure staking mechanism with minimum stake requirement
- **Daily Rewards**: Active nodes earn STX rewards on a daily basis
- **Oracle Verification**: Admin-controlled activity verification system
- **Secure Unstaking**: Cooldown period protects network stability

## Technical Specifications

### Constants

| Name | Value | Description |
|------|--------|------------|
| `MIN_STAKE_AMOUNT` | 0.1 STX | Minimum required stake |
| `REWARD_INTERVAL` | 144 blocks | ~24 hours reward interval |
| `REWARD_AMOUNT` | 0.01 STX | Daily reward per node |
| `COOLDOWN_BLOCKS` | 288 blocks | ~2 days unstaking period |

### Error Codes

| Code | Value | Description |
|------|-------|------------|
| `ERR_UNAUTHORIZED` | u100 | Caller not authorized |
| `ERR_ALREADY_REGISTERED` | u101 | Node already registered |
| `ERR_NOT_REGISTERED` | u102 | Node not registered |
| `ERR_INSUFFICIENT_STAKE` | u103 | Stake amount too low |
| `ERR_TOO_SOON` | u104 | Action attempted too soon |
| `ERR_NOT_ACTIVE` | u105 | Node not active |
| `ERR_NOT_ELIGIBLE` | u106 | Node not eligible |

## Usage

### Node Registration
```clarity
(contract-call? .infralink register-node)
```

### Staking
```clarity
(contract-call? .infralink stake)
```

### Claiming Rewards
```clarity
(contract-call? .infralink claim-reward)
```

### Initiating Unstake
```clarity
(contract-call? .infralink pause-node)
```

### Completing Unstake
```clarity
(contract-call? .infralink unstake)
```

## Development

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet)
- Node.js and npm


## Security

The contract includes several security measures:
- Minimum stake requirement
- Cooldown period for unstaking
- Oracle-based verification
- Admin-controlled node activity tracking

