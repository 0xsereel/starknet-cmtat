#!/bin/bash
# Cairo CMTAT Snapshot Demo Script

set -e

echo "=== Cairo CMTAT Snapshot Demo ==="

# Load environment
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found. Run quick_deploy.sh first."
    exit 1
fi

echo "Demonstrating snapshot functionality with:"
echo "  Debt CMTAT: $DEBT_CMTAT"
echo "  Snapshot Engine: $SNAPSHOT_ENGINE"
echo ""

# Current state
echo "1. Current token state:"
echo "   Total Supply:"
TOTAL_SUPPLY=$(starkli call $DEBT_CMTAT total_supply --network $NETWORK)
echo "   $TOTAL_SUPPLY"

echo "   Admin Balance:"
starkli call $DEBT_CMTAT balance_of $ADMIN_ADDR --network $NETWORK

echo "   Next Snapshot ID:"
NEXT_ID=$(starkli call $SNAPSHOT_ENGINE get_next_snapshot_id --network $NETWORK)
echo "   $NEXT_ID"
echo ""

# Schedule snapshot
echo "2. Scheduling new snapshot..."
SNAPSHOT_TIME=$(($(date +%s) + 30))
echo "   Scheduling for timestamp: $SNAPSHOT_TIME"

echo "   Enter keystore password when prompted:"
starkli invoke $SNAPSHOT_ENGINE schedule_snapshot $SNAPSHOT_TIME \
  --network $NETWORK --account $ACCOUNT_FILE --keystore $KEYSTORE_FILE

echo "   Waiting for confirmation..."
sleep 15

# Check new snapshot ID
echo "3. Checking updated snapshot state..."
NEW_NEXT_ID=$(starkli call $SNAPSHOT_ENGINE get_next_snapshot_id --network $NETWORK)
echo "   New Next ID: $NEW_NEXT_ID"

# Calculate snapshot ID
SNAPSHOT_ID=$(($(echo $NEW_NEXT_ID | grep -o '0x[0-9a-fA-F]*' | head -1 | printf '%d' 0x$(cat)) - 1))
echo "   Scheduled Snapshot ID: $SNAPSHOT_ID"

# Query snapshot details
echo "4. Querying snapshot details..."
echo "   Snapshot $SNAPSHOT_ID data:"
starkli call $SNAPSHOT_ENGINE get_snapshot $SNAPSHOT_ID --network $NETWORK
echo ""

echo "=== Snapshot Demo Complete! ==="
echo ""
echo "Snapshot $SNAPSHOT_ID has been scheduled successfully."
echo "The snapshot contains scheduling information and is ready for recording."
echo ""
echo "For more advanced snapshot operations, see:"
echo "- SNAPSHOT_QUICKSTART.md"
echo "- SNAPSHOT_WORKFLOW.md"