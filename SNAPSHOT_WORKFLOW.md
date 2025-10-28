# Snapshot Engine Workflow Guide

Complete guide for using the Snapshot Engine with DebtCMTAT contracts on Starknet Sepolia.

## Overview

The snapshot system captures token holder balances at specific points in time, allowing you to query historical data. This is useful for:
- Dividend distributions
- Voting rights calculations
- Historical reporting
- Regulatory compliance

## Architecture

```
DebtCMTAT (Token Contract)
    │
    ├── Uses SnapshotEngine for recording snapshots
    ├── Uses RuleEngine for transfer restrictions
    │
SnapshotEngine
    ├── Owned by Admin
    ├── Authorized to record from Token Contract
    └── Stores historical balances
```

## Deployed Contract Addresses (Your Current Setup)

Based on your deployment history:

```bash
# From your history - update these as needed
ADMIN_ADDR="0x04be1751352810aa8ad733c0f51d952ec4f96efee175ab0cbd0da2d2ea537f50"
CMTAT_TOKEN="0x00343aabb8312f3827c75130e9af815a9c853a0a60f7acf4772909624bbf5800"
SNAPSHOT_ENGINE="0x03ce27ac28663313f405e1ec9641c0aad1d8028b42aaf86d5121ddf7304c5061"
RULE_ENGINE="0x07e74747c0d3e6cb68a9e19c6409e8a5aab4e9853c9ee4188c3359fa15a936dd"
SNAPSHOT_DEMO="0x0046c2901fbce8da092ae3654e4d350781ec4aed7a9aa426ef03066fba3d6a8a"
```

## Step-by-Step Snapshot Workflow

### Prerequisites

```bash
# Set your environment
export NETWORK="sepolia"
export ACCOUNT="/Users/lancedavis/.starknet-accounts/account.json"
export KEYSTORE="/Users/lancedavis/.starknet-wallets/keystore.json"
```

### Step 1: Check Current State

```bash
# Check total supply
starkli call $CMTAT_TOKEN total_supply --network $NETWORK

# Check your balance
starkli call $CMTAT_TOKEN balance_of $ADMIN_ADDR --network $NETWORK

# Check next snapshot ID
starkli call $SNAPSHOT_ENGINE get_next_snapshot_id --network $NETWORK
```

### Step 2: Schedule a Snapshot

Schedule a snapshot for a specific timestamp (Unix epoch time).

```bash
# Get current timestamp
CURRENT_TIME=$(date +%s)
echo "Current time: $CURRENT_TIME"

# Schedule snapshot for 1 hour from now
SNAPSHOT_TIME=$((CURRENT_TIME + 3600))
echo "Scheduling snapshot for: $SNAPSHOT_TIME"

# Schedule the snapshot (requires DEBT_ROLE in DebtCMTAT)
starkli invoke $CMTAT_TOKEN \
    schedule_snapshot \
    u64:$SNAPSHOT_TIME \
    --network $NETWORK \
    --account $ACCOUNT \
    --keystore $KEYSTORE
```

**Expected Output:** Transaction hash confirming the snapshot was scheduled.

### Step 3: Record the Snapshot

Once the scheduled time has passed (or immediately for testing), record the snapshot data.

```bash
# Get the snapshot ID that was just scheduled
# The ID is incremented when you call schedule_snapshot
# If get_next_snapshot_id returns 2, then snapshot ID 1 was just scheduled
NEXT_ID=$(starkli call $SNAPSHOT_ENGINE get_next_snapshot_id --network $NETWORK | grep -o '0x[0-9]*' | head -1)
SNAPSHOT_ID=$((NEXT_ID - 1))
echo "Recording snapshot ID: $SNAPSHOT_ID"

# Record the snapshot (this captures total_supply at this moment)
starkli invoke $CMTAT_TOKEN \
    record_snapshot \
    $SNAPSHOT_ID \
    --network $NETWORK \
    --account $ACCOUNT \
    --keystore $KEYSTORE
```

### Step 4: Record Individual Holder Balances (Optional)

The `record_snapshot` function only captures the total supply. To query individual balances later, you need to record them separately. There are two ways:

#### Option A: Record Single Balance

```bash
# Record balance for a specific holder
starkli invoke $SNAPSHOT_ENGINE \
    record_balance \
    $SNAPSHOT_ID \
    $ADMIN_ADDR \
    u256:1000000000000000000000000 \
    --network $NETWORK \
    --account $ACCOUNT \
    --keystore $KEYSTORE
```

**Note:** This requires calling from the authorized token contract. For manual recording, you would need to:
1. Temporarily set the caller as an authorized token contract, OR
2. Use the DebtCMTAT contract to call the snapshot engine

#### Option B: Batch Record Multiple Balances

For multiple holders, use the batch recording function (must be called through a contract):

```cairo
// In your contract
let accounts = array![holder1, holder2, holder3];
let balances = array![balance1, balance2, balance3];
snapshot_recording.batch_record_balances(snapshot_id, accounts, balances);
```

### Step 5: Query Snapshot Data

```bash
# Get snapshot metadata
starkli call $SNAPSHOT_ENGINE \
    get_snapshot \
    $SNAPSHOT_ID \
    --network $NETWORK

# Expected output: (id, timestamp, total_supply)
# Example: [0x1, 0x6540a4c0, 0xd3c21bcecceda1000000]

# Get total supply at snapshot
starkli call $SNAPSHOT_ENGINE \
    total_supply_at \
    $SNAPSHOT_ID \
    --network $NETWORK

# Get specific account balance at snapshot (if recorded)
starkli call $SNAPSHOT_ENGINE \
    balance_of_at \
    $ADMIN_ADDR \
    $SNAPSHOT_ID \
    --network $NETWORK
```

## Complete Example Workflow

Here's a complete example that schedules, records, and queries a snapshot:

```bash
#!/bin/bash

# Configuration
NETWORK="sepolia"
ACCOUNT="/Users/lancedavis/.starknet-accounts/account.json"
KEYSTORE="/Users/lancedavis/.starknet-wallets/keystore.json"

ADMIN_ADDR="0x04be1751352810aa8ad733c0f51d952ec4f96efee175ab0cbd0da2d2ea537f50"
CMTAT_TOKEN="0x00343aabb8312f3827c75130e9af815a9c853a0a60f7acf4772909624bbf5800"
SNAPSHOT_ENGINE="0x03ce27ac28663313f405e1ec9641c0aad1d8028b42aaf86d5121ddf7304c5061"

echo "=== Snapshot Workflow Example ==="

# 1. Check current state
echo -e "\n1. Checking current state..."
starkli call $CMTAT_TOKEN total_supply --network $NETWORK

# 2. Schedule snapshot
echo -e "\n2. Scheduling snapshot..."
SNAPSHOT_TIME=$(($(date +%s) + 60))
starkli invoke $CMTAT_TOKEN schedule_snapshot u64:$SNAPSHOT_TIME \
    --network $NETWORK --account $ACCOUNT --keystore $KEYSTORE

# Wait for confirmation
sleep 15

# 3. Get snapshot ID
echo -e "\n3. Getting snapshot ID..."
NEXT_ID=$(starkli call $SNAPSHOT_ENGINE get_next_snapshot_id --network $NETWORK | grep -o '0x[0-9]*' | head -1)
SNAPSHOT_ID=$((NEXT_ID - 1))
echo "Snapshot ID: $SNAPSHOT_ID"

# 4. Record the snapshot
echo -e "\n4. Recording snapshot..."
starkli invoke $CMTAT_TOKEN record_snapshot $SNAPSHOT_ID \
    --network $NETWORK --account $ACCOUNT --keystore $KEYSTORE

# Wait for confirmation
sleep 15

# 5. Query snapshot
echo -e "\n5. Querying snapshot data..."
starkli call $SNAPSHOT_ENGINE get_snapshot $SNAPSHOT_ID --network $NETWORK
starkli call $SNAPSHOT_ENGINE total_supply_at $SNAPSHOT_ID --network $NETWORK

echo -e "\n=== Workflow Complete ==="
```

## Troubleshooting

### Authorization Error: "Snapshot: unauthorized"

**Problem:** The SnapshotEngine rejects calls from the token contract.

**Solution:** Update the SnapshotEngine's authorized token contract:

```bash
# First, verify current token contract
starkli call $SNAPSHOT_ENGINE get_token_contract --network $NETWORK

# If it's wrong, update it (requires owner)
starkli invoke $SNAPSHOT_ENGINE \
    set_token_contract \
    $CMTAT_TOKEN \
    --network $NETWORK \
    --account $ACCOUNT \
    --keystore $KEYSTORE
```

### Cannot Record Balances

**Problem:** Individual balance recording fails with authorization error.

**Cause:** The `record_balance` function requires the caller to be the authorized token contract. Manual CLI calls won't work directly.

**Solution:** 
1. Add a function in DebtCMTAT that internally calls the snapshot engine:

```cairo
fn record_holder_balance(
    ref self: ContractState,
    snapshot_id: u64,
    account: ContractAddress
) {
    self.access_control.assert_only_role(DEBT_ROLE);
    let balance = self.erc20.balance_of(account);
    let snapshot_engine = ISnapshotRecordingDispatcher { 
        contract_address: self.snapshot_engine.read() 
    };
    snapshot_engine.record_balance(snapshot_id, account, balance);
}
```

2. Or record all balances during the snapshot creation by extending the `record_snapshot` function.

### Snapshot ID Mismatch

**Problem:** Getting wrong snapshot ID.

**Solution:** The `get_next_snapshot_id` returns the NEXT ID that will be used. If it returns 2, then:
- Snapshot ID 1 was already scheduled/used
- The next call to `schedule_snapshot` will use ID 2

Always use `next_id - 1` for the most recent snapshot.

## Best Practices

1. **Schedule First, Record Later:** Always call `schedule_snapshot` before `record_snapshot` to properly track the snapshot metadata.

2. **Verify Authorization:** Ensure the SnapshotEngine has the correct token contract address configured.

3. **Batch Operations:** For multiple holders, implement batch recording in your contract to save gas.

4. **Timestamp Planning:** Schedule snapshots at predictable times (e.g., end of month, specific voting deadlines).

5. **Event Monitoring:** Monitor the `SnapshotScheduled`, `SnapshotCreated`, and `BalanceRecorded` events to track snapshot activities.

## Advanced: Automated Snapshot Recording

For production use, consider implementing an automated system that:

1. Monitors scheduled snapshots
2. Automatically records snapshots when their timestamp is reached
3. Batch records all holder balances
4. Emits events for off-chain indexing

Example contract snippet:

```cairo
fn automated_snapshot_recording(ref self: ContractState, snapshot_id: u64) {
    self.access_control.assert_only_role(SNAPSHOT_ROLE);
    
    // Record the snapshot
    self.record_snapshot(snapshot_id);
    
    // Get all holders (would need to track this)
    let holders = self.get_all_holders();
    let mut accounts = ArrayTrait::new();
    let mut balances = ArrayTrait::new();
    
    // Collect balances
    let mut i = 0;
    loop {
        if i >= holders.len() {
            break;
        }
        let holder = *holders.at(i);
        let balance = self.erc20.balance_of(holder);
        accounts.append(holder);
        balances.append(balance);
        i += 1;
    };
    
    // Batch record
    let snapshot_engine = ISnapshotRecordingDispatcher { 
        contract_address: self.snapshot_engine.read() 
    };
    snapshot_engine.batch_record_balances(snapshot_id, accounts, balances);
}
```

## Additional Resources

- [Cairo Book - Smart Contracts](https://book.cairo-lang.org/)
- [Starknet Documentation](https://docs.starknet.io/)
- [OpenZeppelin Cairo Contracts](https://docs.openzeppelin.com/contracts-cairo/)

## Support

For issues or questions:
1. Check the error messages carefully
2. Verify all contract addresses are correct
3. Ensure you have the necessary roles (DEBT_ROLE for DebtCMTAT operations)
4. Check transaction status on [Starkscan](https://sepolia.starkscan.co/)
