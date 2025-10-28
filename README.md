# Cairo CMTAT - CMTAT Token Implementation for Starknet

A comprehensive implementation of CMTAT (Capital Markets and Technology Association Token) standard in Cairo for Starknet, featuring advanced compliance engines for regulated securities.

## Overview

This project implements the CMTAT token standard in Cairo with:
- ✅ **ERC20 Compliance**: Full ERC20 token functionality
- ✅ **Access Control**: Role-based permissions (Admin, Minter, Burner, Debt)
- ✅ **Rule Engine**: Transfer restriction enforcement (ERC-1404 compatible)
- ✅ **Snapshot Engine**: Historical balance tracking for compliance
- ✅ **Debt Securities**: Specialized implementation for debt instruments
- ✅ **OpenZeppelin Components**: Built on battle-tested contracts

## Features

### Core CMTAT Functionality

1. **Role-Based Access Control**
   - `DEFAULT_ADMIN_ROLE`: Full administrative control
   - `MINTER_ROLE`: Mint new tokens
   - `BURNER_ROLE`: Burn tokens
   - `DEBT_ROLE`: Debt-specific operations

2. **Compliance Engines**
   - **Rule Engine**: Address whitelisting, transfer restrictions
   - **Snapshot Engine**: Point-in-time balance recording
   - **ERC-1404 Integration**: Transfer restriction codes and messages

3. **Debt Securities Support**
   - ISIN tracking
   - Maturity date management
   - Interest rate configuration
   - Credit event handling

## Project Structure

```
cairo-cmtat/
├── src/
│   ├── lib.cairo                    # Library entry point
│   ├── contracts/                   # CMTAT implementations
│   │   ├── standard_cmtat.cairo    # Full-featured CMTAT
│   │   ├── light_cmtat.cairo       # Lightweight version
│   │   └── debt_cmtat.cairo        # Debt securities implementation
│   ├── engines/                     # Compliance engines
│   │   ├── rule_engine.cairo       # Transfer restrictions
│   │   └── snapshot_engine.cairo   # Historical balance tracking
│   └── interfaces/
│       └── icmtat.cairo            # Interface definitions
├── scripts/                         # Deployment and testing scripts
│   ├── quick_deploy.sh             # One-command deployment
│   ├── test_deployment.sh          # Verify deployment
│   └── snapshot_demo.sh            # Snapshot functionality demo
├── tests/
│   └── cmtat_tests.cairo           # Test suite
├── .env.example                     # Environment template
├── DEPLOYMENT_TESTING.md           # Comprehensive deployment guide
├── ENGINES.md                       # Engine documentation
├── SNAPSHOT_QUICKSTART.md          # Snapshot usage guide
└── SNAPSHOT_WORKFLOW.md            # Detailed snapshot workflow
```

## Quick Start

### Prerequisites

1. **Install Scarb** (Cairo package manager)
```bash
curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh
```

2. **Install Starkli** (Starknet CLI)
```bash
curl https://get.starkli.sh | sh
starkliup
```

### Build and Test

```bash
# Clone and build
git clone <repository-url>
cd cairo-cmtat
scarb build

# Run tests
scarb test
```

### Quick Deployment

Deploy the complete ecosystem with one command:

```bash
# Deploy everything (CMTAT + Engines)
./scripts/quick_deploy.sh

# Test the deployment
./scripts/test_deployment.sh

# Try snapshot functionality
./scripts/snapshot_demo.sh
```

See **[DEPLOYMENT_TESTING.md](./DEPLOYMENT_TESTING.md)** for comprehensive deployment and testing scripts.

## Contract Implementations

### 1. Standard CMTAT (`standard_cmtat.cairo`)
Full-featured implementation with:
- Complete ERC20 functionality
- Address and partial token freezing
- Pause/unpause capabilities
- Information storage

### 2. Light CMTAT (`light_cmtat.cairo`)
Lightweight version with:
- Basic ERC20 functionality
- Essential compliance features
- Reduced storage footprint

### 3. Debt CMTAT (`debt_cmtat.cairo`)
Specialized for debt securities:
- ISIN identification
- Maturity date tracking
- Interest rate management
- Credit event handling
- Integrated rule and snapshot engines

## Engines

### Rule Engine
Controls transfer restrictions for compliance:

```cairo
// Deploy rule engine
let rule_engine = deploy_rule_engine(admin);

// Whitelist an address
rule_engine.whitelist_address(address);

// Check transfer restriction
let code = rule_engine.detect_transfer_restriction(from, to, amount);
```

### Snapshot Engine
Records historical balances for compliance reporting:

```cairo
// Deploy snapshot engine
let snapshot_engine = deploy_snapshot_engine(admin, token_address);

// Schedule a snapshot
let snapshot_id = snapshot_engine.schedule_snapshot(timestamp);

// Record current balances
snapshot_engine.record_snapshot(snapshot_id, total_supply);

// Query historical data
let supply = snapshot_engine.total_supply_at(snapshot_id);
```

See [SNAPSHOT_QUICKSTART.md](./SNAPSHOT_QUICKSTART.md) for detailed usage.

## Deployment

### Basic Deployment

```bash
# Declare contract class
starkli declare target/dev/cairo_cmtat_DebtCMTAT.contract_class.json --network sepolia

# Deploy with engines
starkli deploy <CLASS_HASH> \
  <admin> <name> <symbol> <supply> <recipient> \
  <terms> <flag> <isin> <maturity> <rate> <par_value> \
  <rule_engine> <snapshot_engine> \
  --network sepolia
```

### Integration Example

```cairo
// Deploy debt CMTAT with engines for complete compliance
let debt_cmtat = deploy_debt_cmtat(
    admin: admin_address,
    name: "Corporate Bond 2025",
    symbol: "CORP25",
    initial_supply: 1000000 * 10^18,
    isin: "US1234567890",
    maturity: 1735689600, // 2025-01-01
    interest_rate: 5, // 5%
    rule_engine: rule_engine_address,
    snapshot_engine: snapshot_engine_address
);
```

## Testing

```bash
# Run all tests
scarb test

# Test output example
test cairo_cmtat_cmtat_tests::cmtat_tests::test_basic_functionality ... ok
test cairo_cmtat_cmtat_tests::cmtat_tests::test_simple_math ... ok
test result: ok. 2 passed; 0 failed; 0 ignored; 0 filtered out;
```

## Documentation

- **[ENGINES.md](./ENGINES.md)**: Comprehensive engine documentation
- **[SNAPSHOT_QUICKSTART.md](./SNAPSHOT_QUICKSTART.md)**: Quick snapshot setup
- **[SNAPSHOT_WORKFLOW.md](./SNAPSHOT_WORKFLOW.md)**: Detailed snapshot workflow

## Technical Stack

- **Cairo**: v2.6.3+
- **Scarb**: v2.6.4+
- **OpenZeppelin Cairo**: v0.13.0
- **Starknet Foundry**: v0.25.0

## Security Considerations

1. **Role Management**: Carefully assign and manage roles
2. **Engine Integration**: Ensure proper authorization between contracts
3. **Snapshot Timing**: Coordinate snapshot scheduling for compliance
4. **Audit**: Professional security audit recommended for production

## License

Mozilla Public License 2.0 (MPL-2.0)

## References

- [CMTAT Solidity Implementation](https://github.com/CMTA/CMTAT)
- [OpenZeppelin Cairo Contracts](https://github.com/OpenZeppelin/cairo-contracts)
- [Cairo Documentation](https://book.cairo-lang.org/)
- [Starknet Documentation](https://docs.starknet.io/)

---

**Built for regulated securities on Starknet** 🛡️
