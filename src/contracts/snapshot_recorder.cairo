// SPDX-License-Identifier: MPL-2.0
// Simple Snapshot Recorder - Demo for recording snapshots

use starknet::ContractAddress;

#[starknet::interface]
trait ISnapshotRecorder<TContractState> {
    fn record_snapshot_for_token(ref self: TContractState, snapshot_engine: ContractAddress, token_contract: ContractAddress, snapshot_id: u64);
}

#[starknet::contract]
mod SnapshotRecorder {
    use starknet::{ContractAddress, get_caller_address, contract_address_const};
    use cairo_cmtat::engines::snapshot_engine::{ISnapshotRecordingDispatcher, ISnapshotRecordingDispatcherTrait};
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    #[storage]
    struct Storage {
        admin: ContractAddress
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: ContractAddress) {
        self.admin.write(admin);
    }

    #[abi(embed_v0)]
    impl SnapshotRecorderImpl of super::ISnapshotRecorder<ContractState> {
        fn record_snapshot_for_token(ref self: ContractState, snapshot_engine: ContractAddress, token_contract: ContractAddress, snapshot_id: u64) {
            assert(get_caller_address() == self.admin.read(), 'Only admin');
            
            // Get total supply from token contract
            let token = IERC20Dispatcher { contract_address: token_contract };
            let total_supply = token.total_supply();
            
            // Record snapshot (this will still fail due to authorization, but demonstrates the data flow)
            let snapshot_recording = ISnapshotRecordingDispatcher { contract_address: snapshot_engine };
            snapshot_recording.record_snapshot(snapshot_id, total_supply);
        }
    }
}