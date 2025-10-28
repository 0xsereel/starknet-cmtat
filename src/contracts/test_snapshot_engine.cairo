// SPDX-License-Identifier: MPL-2.0
// Test Snapshot Engine - Allows owner to record for demo

use starknet::ContractAddress;

#[starknet::interface]
trait ITestSnapshotEngine<TContractState> {
    fn schedule_snapshot(ref self: TContractState, timestamp: u64) -> u64;
    fn record_snapshot_as_owner(ref self: TContractState, snapshot_id: u64, total_supply: u256);
    fn get_snapshot(self: @TContractState, snapshot_id: u64) -> (u64, u256, u64, u64);
    fn get_next_snapshot_id(self: @TContractState) -> u64;
    fn total_supply_at(self: @TContractState, snapshot_id: u64) -> u256;
}

#[starknet::contract]
mod TestSnapshotEngine {
    use openzeppelin::access::ownable::OwnableComponent;
    use starknet::{ContractAddress, get_block_timestamp};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        snapshots: LegacyMap<u64, (u64, u256, u64, u64)>, // timestamp, total_supply, block_number, recorded_at
        next_snapshot_id: u64,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        SnapshotScheduled: SnapshotScheduled,
        SnapshotRecorded: SnapshotRecorded,
    }

    #[derive(Drop, starknet::Event)]
    struct SnapshotScheduled {
        #[key]
        pub snapshot_id: u64,
        pub timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct SnapshotRecorded {
        #[key]
        pub snapshot_id: u64,
        pub total_supply: u256,
        pub recorded_at: u64,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.ownable.initializer(owner);
        self.next_snapshot_id.write(1);
    }

    #[abi(embed_v0)]
    impl TestSnapshotEngineImpl of super::ITestSnapshotEngine<ContractState> {
        fn schedule_snapshot(ref self: ContractState, timestamp: u64) -> u64 {
            self.ownable.assert_only_owner();
            let snapshot_id = self.next_snapshot_id.read();
            self.snapshots.write(snapshot_id, (timestamp, 0, 0, 0));
            self.next_snapshot_id.write(snapshot_id + 1);
            self.emit(SnapshotScheduled { snapshot_id, timestamp });
            snapshot_id
        }

        fn record_snapshot_as_owner(ref self: ContractState, snapshot_id: u64, total_supply: u256) {
            self.ownable.assert_only_owner();
            let (timestamp, _, block_number, _) = self.snapshots.read(snapshot_id);
            assert(timestamp != 0, 'Snapshot not scheduled');
            
            let recorded_at = get_block_timestamp();
            self.snapshots.write(snapshot_id, (timestamp, total_supply, block_number, recorded_at));
            self.emit(SnapshotRecorded { snapshot_id, total_supply, recorded_at });
        }

        fn get_snapshot(self: @ContractState, snapshot_id: u64) -> (u64, u256, u64, u64) {
            self.snapshots.read(snapshot_id)
        }

        fn get_next_snapshot_id(self: @ContractState) -> u64 {
            self.next_snapshot_id.read()
        }

        fn total_supply_at(self: @ContractState, snapshot_id: u64) -> u256 {
            let (_, total_supply, _, _) = self.snapshots.read(snapshot_id);
            total_supply
        }
    }
}