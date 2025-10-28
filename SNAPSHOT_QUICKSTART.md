# Snapshot Engine Quick Start Guide

Quick reference for performing snapshots with your existing deployed contracts on Sepolia.

## Your Deployed Contracts

```bash
ADMIN_ADDR="0x04be1751352810aa8ad733c0f51d952ec4f96efee175ab0cbd0da2d2ea537f50"
CMTAT_TOKEN="0x00343aabb8312f3827c75130e9af815a9c853a0a60f7acf4772909624bbf5800"
SNAPSHOT_ENGINE="0x03ce27ac28663313f405e1ec9641c0aad1d8028b42aaf86d5121ddf7304c5061"
RULE_ENGINE="0x07e74747c0d3e6cb68a9e19c6409e8a5aab4e9853c9ee4188c3359fa15a936dd"

NETWORK="sepolia"
ACCOUNT="/Users/lancedavis/.starknet-accounts/account.json"
KEYSTORE="/Users/lancedavis/.starknet-wallets/keystore.json"
```

## Fix Authorization Issue (ONE TIME)

The error "Snapshot: unauthorized" occurs because the SnapshotEngine doesn't know about your CMTAT token contract. Fix it once:

```bash
# Check current authorized token
starkli call $SNAPSHOT_ENGINE get_token_contract --network $NETWORK

starkli call $SNAPSHOT_ENGINE get_token_contract --network $NETWORK

# Update to your CMTAT token address
starkli invoke $SNAPSHOT_ENGINE \
    set_token_contract \
    $CMTAT_TOKEN \
    --network $NETWORK \
    --account $ACCOUNT \
    --keystore $KEYSTORE
```

**Wait 10-15 seconds for confirmation, then verify:**

```bash
# Should now return your CMTAT token address
starkli call $SNAPSHOT_ENGINE get_token_contract --network $NETWORK
```

## Complete Snapshot Workflow (5 Steps)

### 1. Check Current State

```bash
# Check total supply
starkli call $CMTAT_TOKEN total_supply --network $NETWORK

# Check your balance
starkli call $CMTAT_TOKEN balance_of $ADMIN_ADDR --network $NETWORK

# Check next snapshot ID (remember this number)
starkli call $SNAPSHOT_ENGINE get_next_snapshot_id --network $NETWORK
```

### 2. Schedule Snapshot

```bash
# Schedule snapshot for current time (for testing) or future time
SNAPSHOT_TIME=$(date +%s)

starkli invoke $CMTAT_TOKEN \
    schedule_snapshot \
    u64:$SNAPSHOT_TIME \
    --network $NETWORK \
    --account $ACCOUNT \
    --keystore $KEYSTORE
```

**Wait 10-15 seconds for confirmation.**

### 3. Get Snapshot ID

```bash
# The snapshot ID is: (next_snapshot_id - 1)
NEXT_ID=$(starkli call $SNAPSHOT_ENGINE get_next_snapshot_id --network $NETWORK)
# If NEXT_ID shows [0x2], then SNAPSHOT_ID = 1
```

Use the appropriate snapshot ID (typically 1 for first snapshot, 2 for second, etc.)

### 4. Record Snapshot

```bash
# Replace 1 with your actual snapshot ID
SNAPSHOT_ID=1

starkli invoke $CMTAT_TOKEN \
    record_snapshot \
    $SNAPSHOT_ID \
    --network $NETWORK \
    --account $ACCOUNT \
    --keystore $KEYSTORE
```

**Wait 10-15 seconds for confirmation.**

### 5. Query Snapshot

```bash
# Get snapshot details
starkli call $SNAPSHOT_ENGINE get_snapshot $SNAPSHOT_ID --network $NETWORK

# Get total supply at snapshot
starkli call $SNAPSHOT_ENGINE total_supply_at $SNAPSHOT_ID --network $NETWORK
```

## Copy-Paste Complete Workflow

Here's the complete workflow you can copy and run (after fixing authorization):

```bash
# Environment setup
export ADMIN_ADDR="0x04be1751352810aa8ad733c0f51d952ec4f96efee175ab0cbd0da2d2ea537f50"
export CMTAT_TOKEN="0x00343aabb8312f3827c75130e9af815a9c853a0a60f7acf4772909624bbf5800"
export SNAPSHOT_ENGINE="0x03ce27ac28663313f405e1ec9641c0aad1d8028b42aaf86d5121ddf7304c5061"
export NETWORK="sepolia"
export ACCOUNT="/Users/lancedavis/.starknet-accounts/account.json"
export KEYSTORE="/Users/lancedavis/.starknet-wallets/keystore.json"

# Check state
echo "=== Checking Current State ==="
starkli call $CMTAT_TOKEN total_supply --network $NETWORK
starkli call $SNAPSHOT_ENGINE get_next_snapshot_id --network $NETWORK

# Schedule snapshot
echo -e "\n=== Scheduling Snapshot ==="
SNAPSHOT_TIME=$(date +%s)
starkli invoke $CMTAT_TOKEN schedule_snapshot u64:$SNAPSHOT_TIME --network $NETWORK --account $ACCOUNT --keystore $KEYSTORE
sleep 15

# Get snapshot ID
echo -e "\n=== Getting Snapshot ID ==="
NEXT_ID=$(starkli call $SNAPSHOT_ENGINE get_next_snapshot_id --network $NETWORK | grep -o '0x[0-9]*' | head -1)
SNAPSHOT_ID=$(printf "%d" $((NEXT_ID - 1)))
echo "Snapshot ID: $SNAPSHOT_ID"

# Record snapshot
echo -e "\n=== Recording Snapshot ==="
starkli invoke $CMTAT_TOKEN record_snapshot $SNAPSHOT_ID --network $NETWORK --account $ACCOUNT --keystore $KEYSTORE
sleep 15

# Query results
echo -e "\n=== Querying Snapshot ==="
starkli call $SNAPSHOT_ENGINE get_snapshot $SNAPSHOT_ID --network $NETWORK
starkli call $SNAPSHOT_ENGINE total_supply_at $SNAPSHOT_ID --network $NETWORK

echo -e "\n=== Complete! ==="
```

## Troubleshooting Quick Fixes

### Still Getting "unauthorized" Error?

```bash
# Double-check the authorized token address
starkli call $SNAPSHOT_ENGINE get_token_contract --network $NETWORK

# It should show your CMTAT token address
# If not, run the set_token_contract command again
```

### Wrong Snapshot ID?

```bash
# List all snapshots (try IDs 1, 2, 3...)
starkli call $SNAPSHOT_ENGINE get_snapshot 1 --network $NETWORK
starkli call $SNAPSHOT_ENGINE get_snapshot 2 --network $NETWORK
```

### Need to Schedule from SnapshotEngine Directly?

If you have owner access to the SnapshotEngine:

```bash
starkli invoke $SNAPSHOT_ENGINE \
    schedule_snapshot \
    u64:$(date +%s) \
    --network $NETWORK \
    --account $ACCOUNT \
    --keystore $KEYSTORE
```

## What Each Command Does

1. **schedule_snapshot**: Reserves a snapshot ID and timestamp (owner only)
2. **record_snapshot**: Captures the total supply at that snapshot ID (requires DEBT_ROLE)
3. **get_snapshot**: Retrieves snapshot metadata (anyone can call)
4. **total_supply_at**: Gets the total supply that was recorded (anyone can call)
5. **balance_of_at**: Gets a holder's balance (if it was recorded)

## Next Steps

After successfully creating a snapshot:

1. To record individual holder balances, you'll need to extend the DebtCMTAT contract
2. Consider implementing automated snapshot recording
3. Monitor events for snapshot creation
4. Build off-chain indexer for historical queries

For detailed information, see `SNAPSHOT_WORKFLOW.md`.
