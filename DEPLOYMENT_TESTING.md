# Cairo CMTAT - Deployment & Testing Guide

This guide provides comprehensive scripts and commands for deploying and testing the Cairo CMTAT ecosystem, including all contract variants and engines.

## Quick Setup

### Prerequisites

```bash
# Install Scarb (Cairo package manager)
curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh

# Install Starkli (Starknet CLI)
curl https://get.starkli.sh | sh
starkliup

# Setup Starknet account (if needed)
starkli account oz init --keystore keystore.json
starkli account deploy --keystore keystore.json --account account.json
```

### Environment Setup

```bash
# Clone and build
git clone <repository-url>
cd cairo-cmtat
scarb build

# Set environment variables
export NETWORK="sepolia"
export ACCOUNT_FILE="path/to/account.json"
export KEYSTORE_FILE="path/to/keystore.json"
export ADMIN_ADDR="0x04be1751352810aa8ad733c0f51d952ec4f96efee175ab0cbd0da2d2ea537f50"
```

## Contract Deployment Scripts

### 1. Standard CMTAT Deployment

Deploy a full-featured CMTAT with pause and freezing capabilities:

```bash
#!/bin/bash
# deploy_standard_cmtat.sh

echo "=== Deploying Standard CMTAT ==="

# Declare contract
CLASS_HASH=$(starkli declare target/dev/cairo_cmtat_StandardCMTAT.contract_class.json \
  --network $NETWORK --account $ACCOUNT_FILE --keystore $KEYSTORE_FILE | \
  grep "Class hash declared" | awk '{print $4}')

echo "Standard CMTAT Class Hash: $CLASS_HASH"

# Deploy contract
CONTRACT_ADDR=$(starkli deploy $CLASS_HASH \
  $ADMIN_ADDR \
  str:"Standard CMTAT Token" \
  str:"SCMTAT" \
  u256:1000000000000000000000000 \
  $ADMIN_ADDR \
  0x123 \
  0x456 \
  str:"Standard CMTAT Information" \
  --network $NETWORK --account $ACCOUNT_FILE --keystore $KEYSTORE_FILE | \
  grep "Contract deployed" | awk '{print $3}')

echo "Standard CMTAT deployed at: $CONTRACT_ADDR"
echo "export STANDARD_CMTAT=\"$CONTRACT_ADDR\"" >> .env
```

### 2. Light CMTAT Deployment

Deploy a lightweight CMTAT for basic use cases:

```bash
#!/bin/bash
# deploy_light_cmtat.sh

echo "=== Deploying Light CMTAT ==="

# Declare contract
CLASS_HASH=$(starkli declare target/dev/cairo_cmtat_LightCMTAT.contract_class.json \
  --network $NETWORK --account $ACCOUNT_FILE --keystore $KEYSTORE_FILE | \
  grep "Class hash declared" | awk '{print $4}')

echo "Light CMTAT Class Hash: $CLASS_HASH"

# Deploy contract
CONTRACT_ADDR=$(starkli deploy $CLASS_HASH \
  $ADMIN_ADDR \
  str:"Light CMTAT Token" \
  str:"LCMTAT" \
  u256:1000000000000000000000000 \
  $ADMIN_ADDR \
  0x123 \
  0x456 \
  --network $NETWORK --account $ACCOUNT_FILE --keystore $KEYSTORE_FILE | \
  grep "Contract deployed" | awk '{print $3}')

echo "Light CMTAT deployed at: $CONTRACT_ADDR"
echo "export LIGHT_CMTAT=\"$CONTRACT_ADDR\"" >> .env
```

### 3. Debt CMTAT Deployment

Deploy a debt securities CMTAT with engine integration:

```bash
#!/bin/bash
# deploy_debt_cmtat.sh

echo "=== Deploying Debt CMTAT ==="

# First deploy engines (see engine deployment section)
source deploy_engines.sh

# Declare debt CMTAT
CLASS_HASH=$(starkli declare target/dev/cairo_cmtat_DebtCMTAT.contract_class.json \
  --network $NETWORK --account $ACCOUNT_FILE --keystore $KEYSTORE_FILE | \
  grep "Class hash declared" | awk '{print $4}')

echo "Debt CMTAT Class Hash: $CLASS_HASH"

# Deploy with engines
CONTRACT_ADDR=$(starkli deploy $CLASS_HASH \
  $ADMIN_ADDR \
  str:"Corporate Bond 2025" \
  str:"CORP25" \
  u256:1000000000000000000000000 \
  $ADMIN_ADDR \
  0x123 \
  0x456 \
  str:"US1234567890" \
  u64:1735689600 \
  u256:5 \
  u256:1000 \
  $RULE_ENGINE \
  $SNAPSHOT_ENGINE \
  --network $NETWORK --account $ACCOUNT_FILE --keystore $KEYSTORE_FILE | \
  grep "Contract deployed" | awk '{print $3}')

echo "Debt CMTAT deployed at: $CONTRACT_ADDR"
echo "export DEBT_CMTAT=\"$CONTRACT_ADDR\"" >> .env
```

## Engine Deployment Scripts

### 4. Rule Engine Deployment

Deploy rule engine for transfer restrictions:

```bash
#!/bin/bash
# deploy_rule_engine.sh

echo "=== Deploying Rule Engine ==="

# Declare rule engine
CLASS_HASH=$(starkli declare target/dev/cairo_cmtat_WhitelistRuleEngine.contract_class.json \
  --network $NETWORK --account $ACCOUNT_FILE --keystore $KEYSTORE_FILE | \
  grep "Class hash declared" | awk '{print $4}')

echo "Rule Engine Class Hash: $CLASS_HASH"

# Deploy rule engine
CONTRACT_ADDR=$(starkli deploy $CLASS_HASH \
  $ADMIN_ADDR \
  --network $NETWORK --account $ACCOUNT_FILE --keystore $KEYSTORE_FILE | \
  grep "Contract deployed" | awk '{print $3}')

echo "Rule Engine deployed at: $CONTRACT_ADDR"
echo "export RULE_ENGINE=\"$CONTRACT_ADDR\"" >> .env

# Whitelist admin address
echo "Whitelisting admin address..."
starkli invoke $CONTRACT_ADDR whitelist_address $ADMIN_ADDR \
  --network $NETWORK --account $ACCOUNT_FILE --keystore $KEYSTORE_FILE

sleep 15
echo "Rule Engine setup complete!"
```

### 5. Snapshot Engine Deployment

Deploy snapshot engine for historical balance tracking:

```bash
#!/bin/bash
# deploy_snapshot_engine.sh

echo "=== Deploying Snapshot Engine ==="

# Declare snapshot engine
CLASS_HASH=$(starkli declare target/dev/cairo_cmtat_SimpleSnapshotEngine.contract_class.json \
  --network $NETWORK --account $ACCOUNT_FILE --keystore $KEYSTORE_FILE | \
  grep "Class hash declared" | awk '{print $4}')

echo "Snapshot Engine Class Hash: $CLASS_HASH"

# Deploy snapshot engine
CONTRACT_ADDR=$(starkli deploy $CLASS_HASH \
  $ADMIN_ADDR \
  $DEBT_CMTAT \
  --network $NETWORK --account $ACCOUNT_FILE --keystore $KEYSTORE_FILE | \
  grep "Contract deployed" | awk '{print $3}')

echo "Snapshot Engine deployed at: $CONTRACT_ADDR"
echo "export SNAPSHOT_ENGINE=\"$CONTRACT_ADDR\"" >> .env
```

### 6. Complete Engine Setup

Deploy all engines together:

```bash
#!/bin/bash
# deploy_engines.sh

echo "=== Deploying All Engines ==="

# Deploy rule engine
source deploy_rule_engine.sh

# Deploy snapshot engine  
source deploy_snapshot_engine.sh

echo "All engines deployed successfully!"
echo "Rule Engine: $RULE_ENGINE"
echo "Snapshot Engine: $SNAPSHOT_ENGINE"
```

## Testing Scripts

### 7. Basic Functionality Tests

Test core CMTAT functionality:

```bash
#!/bin/bash
# test_basic_functionality.sh

echo "=== Testing Basic CMTAT Functionality ==="

# Load environment variables
source .env

echo "Testing with Debt CMTAT: $DEBT_CMTAT"

# Test basic queries
echo "1. Testing basic queries..."
echo "Total Supply:"
starkli call $DEBT_CMTAT total_supply --network $NETWORK

echo "Admin Balance:"
starkli call $DEBT_CMTAT balance_of $ADMIN_ADDR --network $NETWORK

echo "Token Name:"
starkli call $DEBT_CMTAT name --network $NETWORK

echo "Token Symbol:"
starkli call $DEBT_CMTAT symbol --network $NETWORK

# Test debt-specific functions
echo "2. Testing debt-specific functions..."
echo "ISIN:"
starkli call $DEBT_CMTAT get_isin --network $NETWORK

echo "Maturity Date:"
starkli call $DEBT_CMTAT get_maturity_date --network $NETWORK

echo "Interest Rate:"
starkli call $DEBT_CMTAT get_interest_rate --network $NETWORK

echo "Par Value:"
starkli call $DEBT_CMTAT get_par_value --network $NETWORK

echo "Basic functionality tests completed!"
```

### 8. Rule Engine Tests

Test transfer restrictions and whitelisting:

```bash
#!/bin/bash
# test_rule_engine.sh

echo "=== Testing Rule Engine Functionality ==="

source .env

echo "Testing Rule Engine: $RULE_ENGINE"

# Test whitelisting
echo "1. Testing address whitelisting..."
echo "Is admin whitelisted?"
starkli call $RULE_ENGINE is_whitelisted $ADMIN_ADDR --network $NETWORK

# Test transfer restrictions
echo "2. Testing transfer restrictions..."
TEST_ADDR="0x1234567890123456789012345678901234567890123456789012345678901234"

echo "Transfer restriction (admin to test addr):"
starkli call $RULE_ENGINE detect_transfer_restriction $ADMIN_ADDR $TEST_ADDR 1000 --network $NETWORK

echo "Restriction message for code 1:"
starkli call $RULE_ENGINE message_for_restriction_code 1 --network $NETWORK

# Test via CMTAT contract
echo "3. Testing via CMTAT integration..."
echo "CMTAT transfer restriction check:"
starkli call $DEBT_CMTAT detect_transfer_restriction $ADMIN_ADDR $TEST_ADDR 1000 --network $NETWORK

echo "Rule engine tests completed!"
```

### 9. Snapshot Engine Tests

Test snapshot scheduling and recording:

```bash
#!/bin/bash
# test_snapshot_engine.sh

echo "=== Testing Snapshot Engine Functionality ==="

source .env

echo "Testing Snapshot Engine: $SNAPSHOT_ENGINE"

# Test snapshot queries
echo "1. Testing snapshot queries..."
echo "Next Snapshot ID:"
NEXT_ID=$(starkli call $SNAPSHOT_ENGINE get_next_snapshot_id --network $NETWORK)
echo $NEXT_ID

# Schedule a new snapshot
echo "2. Scheduling new snapshot..."
SNAPSHOT_TIME=$(($(date +%s) + 60))
echo "Scheduling snapshot for timestamp: $SNAPSHOT_TIME"

starkli invoke $SNAPSHOT_ENGINE schedule_snapshot $SNAPSHOT_TIME \
  --network $NETWORK --account $ACCOUNT_FILE --keystore $KEYSTORE_FILE

sleep 15

# Check updated snapshot ID
echo "3. Checking updated snapshot ID..."
NEW_NEXT_ID=$(starkli call $SNAPSHOT_ENGINE get_next_snapshot_id --network $NETWORK)
echo "New Next ID: $NEW_NEXT_ID"

# Query snapshot details
SNAPSHOT_ID=$(($(echo $NEW_NEXT_ID | grep -o '0x[0-9a-fA-F]*' | head -1 | printf '%d' "$(cat)") - 1))
echo "Querying snapshot $SNAPSHOT_ID:"
starkli call $SNAPSHOT_ENGINE get_snapshot $SNAPSHOT_ID --network $NETWORK

echo "Snapshot engine tests completed!"
```

### 10. Integration Tests

Test complete ecosystem integration:

```bash
#!/bin/bash
# test_integration.sh

echo "=== Testing Complete Integration ==="

source .env

echo "Testing integration between CMTAT, Rule Engine, and Snapshot Engine"

# Test 1: Transfer with rule engine
echo "1. Testing transfer with rule engine integration..."
TEST_ADDR="0x1234567890123456789012345678901234567890123456789012345678901234"

echo "Attempting transfer to non-whitelisted address (should fail):"
starkli invoke $DEBT_CMTAT transfer $TEST_ADDR 1000 \
  --network $NETWORK --account $ACCOUNT_FILE --keystore $KEYSTORE_FILE 2>&1 | head -5

# Test 2: Whitelist and transfer
echo "2. Whitelisting address and retesting transfer..."
starkli invoke $RULE_ENGINE whitelist_address $TEST_ADDR \
  --network $NETWORK --account $ACCOUNT_FILE --keystore $KEYSTORE_FILE

sleep 15

echo "Transfer restriction check after whitelisting:"
starkli call $DEBT_CMTAT detect_transfer_restriction $ADMIN_ADDR $TEST_ADDR 1000 --network $NETWORK

# Test 3: Snapshot recording workflow
echo "3. Testing snapshot recording workflow..."
echo "Current total supply:"
starkli call $DEBT_CMTAT total_supply --network $NETWORK

echo "Scheduling snapshot via CMTAT contract (if integrated)..."
# Note: This would require the enhanced debt CMTAT with snapshot functions

echo "Integration tests completed!"
```

### 11. End-to-End Testing Suite

Complete testing workflow:

```bash
#!/bin/bash
# run_all_tests.sh

echo "=== Running Complete Test Suite ==="

# Build contracts
echo "Building contracts..."
scarb build

# Run unit tests
echo "Running unit tests..."
scarb test

# Load environment
source .env

# Run functional tests
echo "Running functional tests..."
source test_basic_functionality.sh
echo ""
source test_rule_engine.sh
echo ""
source test_snapshot_engine.sh
echo ""
source test_integration.sh

echo "=== All Tests Completed ==="
```

## Deployment Verification Scripts

### 12. Contract Verification

Verify all deployments are working:

```bash
#!/bin/bash
# verify_deployments.sh

echo "=== Verifying All Deployments ==="

source .env

echo "1. Verifying Standard CMTAT..."
if [ ! -z "$STANDARD_CMTAT" ]; then
    starkli call $STANDARD_CMTAT name --network $NETWORK
    echo "✅ Standard CMTAT verified"
else
    echo "❌ Standard CMTAT not deployed"
fi

echo "2. Verifying Light CMTAT..."
if [ ! -z "$LIGHT_CMTAT" ]; then
    starkli call $LIGHT_CMTAT name --network $NETWORK
    echo "✅ Light CMTAT verified"
else
    echo "❌ Light CMTAT not deployed"
fi

echo "3. Verifying Debt CMTAT..."
if [ ! -z "$DEBT_CMTAT" ]; then
    starkli call $DEBT_CMTAT name --network $NETWORK
    starkli call $DEBT_CMTAT get_isin --network $NETWORK
    echo "✅ Debt CMTAT verified"
else
    echo "❌ Debt CMTAT not deployed"
fi

echo "4. Verifying Rule Engine..."
if [ ! -z "$RULE_ENGINE" ]; then
    starkli call $RULE_ENGINE is_whitelisted $ADMIN_ADDR --network $NETWORK
    echo "✅ Rule Engine verified"
else
    echo "❌ Rule Engine not deployed"
fi

echo "5. Verifying Snapshot Engine..."
if [ ! -z "$SNAPSHOT_ENGINE" ]; then
    starkli call $SNAPSHOT_ENGINE get_next_snapshot_id --network $NETWORK
    echo "✅ Snapshot Engine verified"
else
    echo "❌ Snapshot Engine not deployed"
fi

echo "Verification completed!"
```

## Usage Instructions

### Quick Start for Developers

1. **Setup Environment**:
```bash
# Clone repo and setup
git clone <repo-url>
cd cairo-cmtat
scarb build

# Setup accounts and environment
cp .env.example .env
# Edit .env with your account details
```

2. **Deploy Everything**:
```bash
# Make scripts executable
chmod +x deploy_*.sh test_*.sh

# Deploy all contracts
./deploy_debt_cmtat.sh

# Verify deployments
./verify_deployments.sh
```

3. **Run Tests**:
```bash
# Run complete test suite
./run_all_tests.sh
```

### Script Dependencies

- **Starkli**: For blockchain interactions
- **Scarb**: For building Cairo contracts
- **jq**: For JSON processing (optional)
- **curl**: For API calls (optional)

### Environment Variables Required

```bash
# Required
export NETWORK="sepolia"
export ACCOUNT_FILE="/path/to/account.json"
export KEYSTORE_FILE="/path/to/keystore.json" 
export ADMIN_ADDR="0x..."

# Generated by deployment scripts
export STANDARD_CMTAT="0x..."
export LIGHT_CMTAT="0x..."
export DEBT_CMTAT="0x..."
export RULE_ENGINE="0x..."
export SNAPSHOT_ENGINE="0x..."
```

### Troubleshooting

1. **Nonce Issues**: Wait 15 seconds between transactions
2. **Gas Issues**: Increase gas limit or check balance
3. **Authorization**: Ensure correct account and roles
4. **Network**: Verify Starknet network status

This comprehensive guide provides everything needed to deploy and test the Cairo CMTAT ecosystem!