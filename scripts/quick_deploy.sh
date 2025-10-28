#!/bin/bash
# Quick deployment script for Cairo CMTAT ecosystem

set -e

echo "=== Cairo CMTAT Quick Deploy ==="

# Check prerequisites
command -v starkli >/dev/null 2>&1 || { echo "starkli required but not installed"; exit 1; }
command -v scarb >/dev/null 2>&1 || { echo "scarb required but not installed"; exit 1; }

# Default values
NETWORK=${NETWORK:-"sepolia"}
ADMIN_ADDR=${ADMIN_ADDR:-"0x04be1751352810aa8ad733c0f51d952ec4f96efee175ab0cbd0da2d2ea537f50"}
ACCOUNT_FILE=${ACCOUNT_FILE:-"~/.starknet-accounts/account.json"}
KEYSTORE_FILE=${KEYSTORE_FILE:-"~/.starknet-wallets/keystore.json"}

echo "Network: $NETWORK"
echo "Admin: $ADMIN_ADDR"

# Build contracts
echo "Building contracts..."
scarb build

# Deploy Rule Engine
echo "Deploying Rule Engine..."
RULE_CLASS=$(starkli declare target/dev/cairo_cmtat_WhitelistRuleEngine.contract_class.json \
  --network $NETWORK --account $ACCOUNT_FILE --keystore $KEYSTORE_FILE 2>/dev/null | \
  grep "Class hash declared" | awk '{print $4}' || echo "Already declared")

if [[ $RULE_CLASS != "Already declared" ]]; then
  echo "Rule Engine Class: $RULE_CLASS"
fi

RULE_ENGINE=$(starkli deploy $RULE_CLASS $ADMIN_ADDR \
  --network $NETWORK --account $ACCOUNT_FILE --keystore $KEYSTORE_FILE 2>/dev/null | \
  grep "Contract deployed" | awk '{print $3}')

echo "Rule Engine: $RULE_ENGINE"

# Deploy Snapshot Engine
echo "Deploying Snapshot Engine..."
SNAPSHOT_CLASS=$(starkli declare target/dev/cairo_cmtat_SimpleSnapshotEngine.contract_class.json \
  --network $NETWORK --account $ACCOUNT_FILE --keystore $KEYSTORE_FILE 2>/dev/null | \
  grep "Class hash declared" | awk '{print $4}' || echo "Already declared")

SNAPSHOT_ENGINE=$(starkli deploy $SNAPSHOT_CLASS $ADMIN_ADDR "0x0" \
  --network $NETWORK --account $ACCOUNT_FILE --keystore $KEYSTORE_FILE 2>/dev/null | \
  grep "Contract deployed" | awk '{print $3}')

echo "Snapshot Engine: $SNAPSHOT_ENGINE"

# Deploy Debt CMTAT
echo "Deploying Debt CMTAT..."
DEBT_CLASS=$(starkli declare target/dev/cairo_cmtat_DebtCMTAT.contract_class.json \
  --network $NETWORK --account $ACCOUNT_FILE --keystore $KEYSTORE_FILE 2>/dev/null | \
  grep "Class hash declared" | awk '{print $4}' || echo "Already declared")

DEBT_CMTAT=$(starkli deploy $DEBT_CLASS \
  $ADMIN_ADDR \
  str:"Cairo CMTAT Debt Token" \
  str:"CCDT" \
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
  --network $NETWORK --account $ACCOUNT_FILE --keystore $KEYSTORE_FILE 2>/dev/null | \
  grep "Contract deployed" | awk '{print $3}')

echo "Debt CMTAT: $DEBT_CMTAT"

# Save to .env file
cat > .env << EOF
# Cairo CMTAT Deployment Configuration
NETWORK="$NETWORK"
ADMIN_ADDR="$ADMIN_ADDR"
RULE_ENGINE="$RULE_ENGINE"
SNAPSHOT_ENGINE="$SNAPSHOT_ENGINE"
DEBT_CMTAT="$DEBT_CMTAT"
ACCOUNT_FILE="$ACCOUNT_FILE"
KEYSTORE_FILE="$KEYSTORE_FILE"
EOF

echo ""
echo "=== Deployment Complete! ==="
echo "All contract addresses saved to .env file"
echo ""
echo "Next steps:"
echo "1. source .env"
echo "2. ./scripts/test_deployment.sh"
echo "3. See DEPLOYMENT_TESTING.md for detailed testing"