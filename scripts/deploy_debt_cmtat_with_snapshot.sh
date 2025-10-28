#!/bin/bash

# Deploy DebtCMTAT with RuleEngine and SnapshotEngine on Sepolia
# This script demonstrates a complete snapshot workflow

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Network configuration
NETWORK="sepolia"
ACCOUNT_FILE="/Users/lancedavis/.starknet-accounts/account.json"
KEYSTORE_FILE="/Users/lancedavis/.starknet-wallets/keystore.json"

# Admin/Owner address (from your history)
ADMIN_ADDRESS="0x04be1751352810aa8ad733c0f51d952ec4f96efee175ab0cbd0da2d2ea537f50"

# Token parameters
TOKEN_NAME="Enhanced Debt CMTAT"
TOKEN_SYMBOL="EDCMTAT"
INITIAL_SUPPLY="1000000000000000000000000"  # 1M tokens (18 decimals)
RECIPIENT=$ADMIN_ADDRESS

# Debt-specific parameters
TERMS="1"
FLAG="1"
ISIN="US12345678901"
MATURITY_DATE="1735689600"  # Example: Dec 31, 2024
INTEREST_RATE="500"  # 5% (in basis points)
PAR_VALUE="1000000000000000000000"  # 1000 tokens

# Class hashes (you'll need to update these after declaring)
RULE_ENGINE_CLASS="0x0785d93d8bde8ed59583d8351a18f5b3d02fe0389d537a4236f57c787606c5d6"
SNAPSHOT_ENGINE_CLASS="0x0785d93d8bde8ed59583d8351a18f5b3d02fe0389d537a4236f57c787606c5d6"
DEBT_CMTAT_CLASS="0x073df1d757f9927b737ae61d1b350aeefa4df2bf1cfc73c47c017b9e80e246e7"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}DebtCMTAT with Snapshot Engine Deployment${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Step 1: Declare contracts if not already declared
echo -e "${YELLOW}Step 1: Declaring contracts...${NC}"
echo "Note: Update the class hashes in this script after declaration"
echo ""

# Uncomment these if you need to declare
# echo "Declaring RuleEngine..."
# starkli declare target/dev/cairo_cmtat_SimpleRuleEngine.contract_class.json \
#     --network $NETWORK \
#     --account $ACCOUNT_FILE \
#     --keystore $KEYSTORE_FILE

# echo "Declaring SnapshotEngine..."
# starkli declare target/dev/cairo_cmtat_SimpleSnapshotEngine.contract_class.json \
#     --network $NETWORK \
#     --account $ACCOUNT_FILE \
#     --keystore $KEYSTORE_FILE

# echo "Declaring DebtCMTAT..."
# starkli declare target/dev/cairo_cmtat_DebtCMTAT.contract_class.json \
#     --network $NETWORK \
#     --account $ACCOUNT_FILE \
#     --keystore $KEYSTORE_FILE

# Step 2: Deploy RuleEngine
echo -e "\n${YELLOW}Step 2: Deploying RuleEngine...${NC}"
RULE_ENGINE_ADDR=$(starkli deploy $RULE_ENGINE_CLASS \
    $ADMIN_ADDRESS \
    0x0 \
    --network $NETWORK \
    --account $ACCOUNT_FILE \
    --keystore $KEYSTORE_FILE | grep "Contract deployed:" | awk '{print $3}')

if [ -z "$RULE_ENGINE_ADDR" ]; then
    echo -e "${RED}Failed to deploy RuleEngine${NC}"
    exit 1
fi
echo -e "${GREEN}✓ RuleEngine deployed at: $RULE_ENGINE_ADDR${NC}"

# Step 3: Deploy SnapshotEngine with placeholder token contract (will update later)
echo -e "\n${YELLOW}Step 3: Deploying SnapshotEngine...${NC}"
PLACEHOLDER_TOKEN="0x0000000000000000000000000000000000000000000000000000000000000001"
SNAPSHOT_ENGINE_ADDR=$(starkli deploy $SNAPSHOT_ENGINE_CLASS \
    $ADMIN_ADDRESS \
    $PLACEHOLDER_TOKEN \
    --network $NETWORK \
    --account $ACCOUNT_FILE \
    --keystore $KEYSTORE_FILE | grep "Contract deployed:" | awk '{print $3}')

if [ -z "$SNAPSHOT_ENGINE_ADDR" ]; then
    echo -e "${RED}Failed to deploy SnapshotEngine${NC}"
    exit 1
fi
echo -e "${GREEN}✓ SnapshotEngine deployed at: $SNAPSHOT_ENGINE_ADDR${NC}"

# Step 4: Deploy DebtCMTAT with engines
echo -e "\n${YELLOW}Step 4: Deploying DebtCMTAT...${NC}"

# Convert string parameters to hex for Cairo
# For ByteArray strings, we'll use the raw strings directly
DEBT_CMTAT_ADDR=$(starkli deploy $DEBT_CMTAT_CLASS \
    $ADMIN_ADDRESS \
    str:"$TOKEN_NAME" \
    str:"$TOKEN_SYMBOL" \
    u256:$INITIAL_SUPPLY \
    $RECIPIENT \
    $TERMS \
    $FLAG \
    str:"$ISIN" \
    u64:$MATURITY_DATE \
    u256:$INTEREST_RATE \
    u256:$PAR_VALUE \
    $RULE_ENGINE_ADDR \
    $SNAPSHOT_ENGINE_ADDR \
    --network $NETWORK \
    --account $ACCOUNT_FILE \
    --keystore $KEYSTORE_FILE | grep "Contract deployed:" | awk '{print $3}')

if [ -z "$DEBT_CMTAT_ADDR" ]; then
    echo -e "${RED}Failed to deploy DebtCMTAT${NC}"
    exit 1
fi
echo -e "${GREEN}✓ DebtCMTAT deployed at: $DEBT_CMTAT_ADDR${NC}"

# Step 5: Update SnapshotEngine with the actual token contract address
echo -e "\n${YELLOW}Step 5: Updating SnapshotEngine token contract...${NC}"
starkli invoke $SNAPSHOT_ENGINE_ADDR \
    set_token_contract \
    $DEBT_CMTAT_ADDR \
    --network $NETWORK \
    --account $ACCOUNT_FILE \
    --keystore $KEYSTORE_FILE

echo -e "${GREEN}✓ SnapshotEngine authorized for DebtCMTAT${NC}"

# Wait for transaction confirmation
echo "Waiting for transaction to confirm..."
sleep 10

# Step 6: Verify deployment
echo -e "\n${YELLOW}Step 6: Verifying deployment...${NC}"

echo "Checking token total supply..."
TOTAL_SUPPLY=$(starkli call $DEBT_CMTAT_ADDR total_supply --network $NETWORK)
echo "Total Supply: $TOTAL_SUPPLY"

echo "Checking admin balance..."
ADMIN_BALANCE=$(starkli call $DEBT_CMTAT_ADDR balance_of $ADMIN_ADDRESS --network $NETWORK)
echo "Admin Balance: $ADMIN_BALANCE"

echo "Checking snapshot engine configuration..."
CONFIGURED_ENGINE=$(starkli call $DEBT_CMTAT_ADDR get_snapshot_engine --network $NETWORK)
echo "Configured Snapshot Engine: $CONFIGURED_ENGINE"

# Step 7: Schedule and execute a snapshot
echo -e "\n${YELLOW}Step 7: Scheduling snapshot...${NC}"
SNAPSHOT_TIMESTAMP=$(date +%s)
SNAPSHOT_TIMESTAMP=$((SNAPSHOT_TIMESTAMP + 60))  # Schedule 60 seconds from now

echo "Scheduling snapshot for timestamp: $SNAPSHOT_TIMESTAMP"
starkli invoke $DEBT_CMTAT_ADDR \
    schedule_snapshot \
    u64:$SNAPSHOT_TIMESTAMP \
    --network $NETWORK \
    --account $ACCOUNT_FILE \
    --keystore $KEYSTORE_FILE

echo "Waiting for transaction to confirm..."
sleep 10

# Step 8: Get the snapshot ID and record the snapshot
echo -e "\n${YELLOW}Step 8: Recording snapshot...${NC}"

NEXT_SNAPSHOT_ID=$(starkli call $SNAPSHOT_ENGINE_ADDR get_next_snapshot_id --network $NETWORK | grep -o '0x[0-9a-fA-F]*' | head -1)
SNAPSHOT_ID=$((NEXT_SNAPSHOT_ID - 1))  # The last scheduled snapshot

echo "Recording snapshot ID: $SNAPSHOT_ID"
starkli invoke $DEBT_CMTAT_ADDR \
    record_snapshot \
    $SNAPSHOT_ID \
    --network $NETWORK \
    --account $ACCOUNT_FILE \
    --keystore $KEYSTORE_FILE

echo "Waiting for transaction to confirm..."
sleep 10

# Step 9: Query snapshot data
echo -e "\n${YELLOW}Step 9: Querying snapshot data...${NC}"

echo "Snapshot details:"
starkli call $SNAPSHOT_ENGINE_ADDR get_snapshot $SNAPSHOT_ID --network $NETWORK

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment and Snapshot Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Contract Addresses:${NC}"
echo "RuleEngine:      $RULE_ENGINE_ADDR"
echo "SnapshotEngine:  $SNAPSHOT_ENGINE_ADDR"
echo "DebtCMTAT:       $DEBT_CMTAT_ADDR"
echo ""
echo -e "${BLUE}Snapshot Info:${NC}"
echo "Snapshot ID:     $SNAPSHOT_ID"
echo "Timestamp:       $SNAPSHOT_TIMESTAMP"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. To check balance at snapshot:"
echo "   starkli call $SNAPSHOT_ENGINE_ADDR balance_of_at $ADMIN_ADDRESS $SNAPSHOT_ID --network $NETWORK"
echo ""
echo "2. To get total supply at snapshot:"
echo "   starkli call $SNAPSHOT_ENGINE_ADDR total_supply_at $SNAPSHOT_ID --network $NETWORK"
echo ""
echo "3. To schedule another snapshot:"
echo "   starkli invoke $DEBT_CMTAT_ADDR schedule_snapshot <timestamp> --network $NETWORK --account $ACCOUNT_FILE --keystore $KEYSTORE_FILE"
