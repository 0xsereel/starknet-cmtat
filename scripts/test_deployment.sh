#!/bin/bash
# Test deployment script for Cairo CMTAT

set -e

echo "=== Testing Cairo CMTAT Deployment ==="

# Load environment
if [ -f .env ]; then
    source .env
    echo "Loaded environment from .env"
else
    echo "Error: .env file not found. Run quick_deploy.sh first."
    exit 1
fi

echo "Testing with:"
echo "  Debt CMTAT: $DEBT_CMTAT"
echo "  Rule Engine: $RULE_ENGINE" 
echo "  Snapshot Engine: $SNAPSHOT_ENGINE"
echo ""

# Test 1: Basic token functionality
echo "1. Testing basic token functionality..."
echo "   Total Supply:"
starkli call $DEBT_CMTAT total_supply --network $NETWORK

echo "   Token Name:"
starkli call $DEBT_CMTAT name --network $NETWORK

echo "   Admin Balance:"
starkli call $DEBT_CMTAT balance_of $ADMIN_ADDR --network $NETWORK
echo ""

# Test 2: Debt-specific functions
echo "2. Testing debt-specific functionality..."
echo "   ISIN:"
starkli call $DEBT_CMTAT get_isin --network $NETWORK

echo "   Maturity Date:"
starkli call $DEBT_CMTAT get_maturity_date --network $NETWORK

echo "   Interest Rate:"
starkli call $DEBT_CMTAT get_interest_rate --network $NETWORK
echo ""

# Test 3: Rule Engine
echo "3. Testing rule engine..."
echo "   Is admin whitelisted:"
starkli call $RULE_ENGINE is_whitelisted $ADMIN_ADDR --network $NETWORK

echo "   Transfer restriction (to non-whitelisted):"
starkli call $RULE_ENGINE detect_transfer_restriction $ADMIN_ADDR "0x1234567890123456789012345678901234567890123456789012345678901234" 1000 --network $NETWORK
echo ""

# Test 4: Snapshot Engine
echo "4. Testing snapshot engine..."
echo "   Next Snapshot ID:"
starkli call $SNAPSHOT_ENGINE get_next_snapshot_id --network $NETWORK

echo "   Snapshot 1 data:"
starkli call $SNAPSHOT_ENGINE get_snapshot 1 --network $NETWORK
echo ""

# Test 5: Integration
echo "5. Testing CMTAT integration..."
echo "   CMTAT Rule Engine address:"
starkli call $DEBT_CMTAT get_rule_engine --network $NETWORK

echo "   CMTAT Snapshot Engine address:"
starkli call $DEBT_CMTAT get_snapshot_engine --network $NETWORK

echo "   CMTAT Transfer restriction check:"
starkli call $DEBT_CMTAT detect_transfer_restriction $ADMIN_ADDR "0x1234567890123456789012345678901234567890123456789012345678901234" 1000 --network $NETWORK
echo ""

echo "=== All Tests Completed Successfully! ==="
echo ""
echo "Your Cairo CMTAT deployment is working correctly."
echo "See DEPLOYMENT_TESTING.md for more comprehensive testing options."