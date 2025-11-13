// SPDX-License-Identifier: MPL-2.0
// CMTAT Factory - Deploy Standard, Debt, and Light CMTAT Implementations

use starknet::{ContractAddress, ClassHash};

#[starknet::interface]
trait ICMTATFactory<TContractState> {
    // Factory configuration
    fn get_standard_class_hash(self: @TContractState) -> ClassHash;
    fn get_debt_class_hash(self: @TContractState) -> ClassHash;
    fn get_light_class_hash(self: @TContractState) -> ClassHash;
    fn set_standard_class_hash(ref self: TContractState, class_hash: ClassHash);
    fn set_debt_class_hash(ref self: TContractState, class_hash: ClassHash);
    fn set_light_class_hash(ref self: TContractState, class_hash: ClassHash);
    
    // Deployment functions
    fn deploy_standard_cmtat(
        ref self: TContractState,
        admin: ContractAddress,
        name: ByteArray,
        symbol: ByteArray,
        initial_supply: u256,
        recipient: ContractAddress,
        terms: felt252,
        information: ByteArray,
        salt: felt252
    ) -> ContractAddress;
    
    fn deploy_debt_cmtat(
        ref self: TContractState,
        admin: ContractAddress,
        name: ByteArray,
        symbol: ByteArray,
        initial_supply: u256,
        recipient: ContractAddress,
        terms: felt252,
        isin: ByteArray,
        maturity_date: u64,
        interest_rate: u256,
        par_value: u256,
        rule_engine: ContractAddress,
        snapshot_engine: ContractAddress,
        salt: felt252
    ) -> ContractAddress;
    
    fn deploy_light_cmtat(
        ref self: TContractState,
        admin: ContractAddress,
        name: ByteArray,
        symbol: ByteArray,
        initial_supply: u256,
        recipient: ContractAddress,
        terms: felt252,
        salt: felt252
    ) -> ContractAddress;
    
    // Query deployed contracts
    fn get_deployment_count(self: @TContractState) -> u256;
    fn get_deployment_at_index(self: @TContractState, index: u256) -> ContractAddress;
    fn is_deployed_by_factory(self: @TContractState, contract_address: ContractAddress) -> bool;
}

#[starknet::contract]
mod CMTATFactory {
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    use starknet::{
        ContractAddress, ClassHash, get_caller_address, syscalls::deploy_syscall,
        SyscallResultTrait
    };
    use core::num::traits::Zero;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        standard_class_hash: ClassHash,
        debt_class_hash: ClassHash,
        light_class_hash: ClassHash,
        deployment_count: u256,
        deployments: LegacyMap<u256, ContractAddress>,
        is_deployed: LegacyMap<ContractAddress, bool>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        StandardCMTATDeployed: StandardCMTATDeployed,
        DebtCMTATDeployed: DebtCMTATDeployed,
        LightCMTATDeployed: LightCMTATDeployed,
        ClassHashUpdated: ClassHashUpdated,
    }

    #[derive(Drop, starknet::Event)]
    struct StandardCMTATDeployed {
        #[key]
        pub contract_address: ContractAddress,
        #[key]
        pub deployer: ContractAddress,
        pub name: ByteArray,
        pub symbol: ByteArray,
        pub admin: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct DebtCMTATDeployed {
        #[key]
        pub contract_address: ContractAddress,
        #[key]
        pub deployer: ContractAddress,
        pub name: ByteArray,
        pub symbol: ByteArray,
        pub admin: ContractAddress,
        pub isin: ByteArray,
    }

    #[derive(Drop, starknet::Event)]
    struct LightCMTATDeployed {
        #[key]
        pub contract_address: ContractAddress,
        #[key]
        pub deployer: ContractAddress,
        pub name: ByteArray,
        pub symbol: ByteArray,
        pub admin: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct ClassHashUpdated {
        pub contract_type: felt252,
        pub old_class_hash: ClassHash,
        pub new_class_hash: ClassHash,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        standard_class_hash: ClassHash,
        debt_class_hash: ClassHash,
        light_class_hash: ClassHash
    ) {
        self.ownable.initializer(owner);
        self.standard_class_hash.write(standard_class_hash);
        self.debt_class_hash.write(debt_class_hash);
        self.light_class_hash.write(light_class_hash);
        self.deployment_count.write(0);
    }

    #[abi(embed_v0)]
    impl CMTATFactoryImpl of super::ICMTATFactory<ContractState> {
        fn get_standard_class_hash(self: @ContractState) -> ClassHash {
            self.standard_class_hash.read()
        }

        fn get_debt_class_hash(self: @ContractState) -> ClassHash {
            self.debt_class_hash.read()
        }

        fn get_light_class_hash(self: @ContractState) -> ClassHash {
            self.light_class_hash.read()
        }

        fn set_standard_class_hash(ref self: ContractState, class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            let old_class_hash = self.standard_class_hash.read();
            self.standard_class_hash.write(class_hash);
            self.emit(ClassHashUpdated {
                contract_type: 'STANDARD_CMTAT',
                old_class_hash,
                new_class_hash: class_hash
            });
        }

        fn set_debt_class_hash(ref self: ContractState, class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            let old_class_hash = self.debt_class_hash.read();
            self.debt_class_hash.write(class_hash);
            self.emit(ClassHashUpdated {
                contract_type: 'DEBT_CMTAT',
                old_class_hash,
                new_class_hash: class_hash
            });
        }

        fn set_light_class_hash(ref self: ContractState, class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            let old_class_hash = self.light_class_hash.read();
            self.light_class_hash.write(class_hash);
            self.emit(ClassHashUpdated {
                contract_type: 'LIGHT_CMTAT',
                old_class_hash,
                new_class_hash: class_hash
            });
        }

        fn deploy_standard_cmtat(
            ref self: ContractState,
            admin: ContractAddress,
            name: ByteArray,
            symbol: ByteArray,
            initial_supply: u256,
            recipient: ContractAddress,
            terms: felt252,
            information: ByteArray,
            salt: felt252
        ) -> ContractAddress {
            let class_hash = self.standard_class_hash.read();
            assert(!class_hash.is_zero(), 'Standard class hash not set');

            // Prepare constructor calldata
            let mut calldata: Array<felt252> = array![];
            Serde::serialize(@admin, ref calldata);
            Serde::serialize(@name, ref calldata);
            Serde::serialize(@symbol, ref calldata);
            Serde::serialize(@initial_supply, ref calldata);
            Serde::serialize(@recipient, ref calldata);
            Serde::serialize(@terms, ref calldata);
            Serde::serialize(@information, ref calldata);

            // Deploy the contract
            let (contract_address, _) = deploy_syscall(
                class_hash, salt, calldata.span(), false
            ).unwrap_syscall();

            // Track deployment
            self._record_deployment(contract_address);

            // Emit event
            self.emit(StandardCMTATDeployed {
                contract_address,
                deployer: get_caller_address(),
                name,
                symbol,
                admin
            });

            contract_address
        }

        fn deploy_debt_cmtat(
            ref self: ContractState,
            admin: ContractAddress,
            name: ByteArray,
            symbol: ByteArray,
            initial_supply: u256,
            recipient: ContractAddress,
            terms: felt252,
            isin: ByteArray,
            maturity_date: u64,
            interest_rate: u256,
            par_value: u256,
            rule_engine: ContractAddress,
            snapshot_engine: ContractAddress,
            salt: felt252
        ) -> ContractAddress {
            let class_hash = self.debt_class_hash.read();
            assert(!class_hash.is_zero(), 'Debt class hash not set');

            // Prepare constructor calldata
            let mut calldata: Array<felt252> = array![];
            Serde::serialize(@admin, ref calldata);
            Serde::serialize(@name, ref calldata);
            Serde::serialize(@symbol, ref calldata);
            Serde::serialize(@initial_supply, ref calldata);
            Serde::serialize(@recipient, ref calldata);
            Serde::serialize(@terms, ref calldata);
            Serde::serialize(@isin, ref calldata);
            Serde::serialize(@maturity_date, ref calldata);
            Serde::serialize(@interest_rate, ref calldata);
            Serde::serialize(@par_value, ref calldata);
            Serde::serialize(@rule_engine, ref calldata);
            Serde::serialize(@snapshot_engine, ref calldata);

            // Deploy the contract
            let (contract_address, _) = deploy_syscall(
                class_hash, salt, calldata.span(), false
            ).unwrap_syscall();

            // Track deployment
            self._record_deployment(contract_address);

            // Emit event
            self.emit(DebtCMTATDeployed {
                contract_address,
                deployer: get_caller_address(),
                name,
                symbol,
                admin,
                isin
            });

            contract_address
        }

        fn deploy_light_cmtat(
            ref self: ContractState,
            admin: ContractAddress,
            name: ByteArray,
            symbol: ByteArray,
            initial_supply: u256,
            recipient: ContractAddress,
            terms: felt252,
            salt: felt252
        ) -> ContractAddress {
            let class_hash = self.light_class_hash.read();
            assert(!class_hash.is_zero(), 'Light class hash not set');

            // Prepare constructor calldata
            let mut calldata: Array<felt252> = array![];
            Serde::serialize(@admin, ref calldata);
            Serde::serialize(@name, ref calldata);
            Serde::serialize(@symbol, ref calldata);
            Serde::serialize(@initial_supply, ref calldata);
            Serde::serialize(@recipient, ref calldata);
            Serde::serialize(@terms, ref calldata);

            // Deploy the contract
            let (contract_address, _) = deploy_syscall(
                class_hash, salt, calldata.span(), false
            ).unwrap_syscall();

            // Track deployment
            self._record_deployment(contract_address);

            // Emit event
            self.emit(LightCMTATDeployed {
                contract_address,
                deployer: get_caller_address(),
                name,
                symbol,
                admin
            });

            contract_address
        }

        fn get_deployment_count(self: @ContractState) -> u256 {
            self.deployment_count.read()
        }

        fn get_deployment_at_index(self: @ContractState, index: u256) -> ContractAddress {
            assert(index < self.deployment_count.read(), 'Index out of bounds');
            self.deployments.read(index)
        }

        fn is_deployed_by_factory(
            self: @ContractState, contract_address: ContractAddress
        ) -> bool {
            self.is_deployed.read(contract_address)
        }
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable._upgrade(new_class_hash);
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _record_deployment(ref self: ContractState, contract_address: ContractAddress) {
            let count = self.deployment_count.read();
            self.deployments.write(count, contract_address);
            self.is_deployed.write(contract_address, true);
            self.deployment_count.write(count + 1);
        }
    }
}
