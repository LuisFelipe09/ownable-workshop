use starknet::ContractAddress;

#[starknet::interface]
trait IOwnable<T>{
    fn owner(self: @T) -> ContractAddress;
    fn transfer_ownership(ref self: T, new_owner: ContractAddress);
    fn renounce_ownership(ref self: T);
}

#[starknet::component]
mod OwnableComponent {
    use starknet::{ContractAddress, get_caller_address, Zeroable};
    use super::IOwnable;

    #[storage]
    struct Storage {
        owner: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OwnershipTransferred: OwnershipTransferred,
    }

    #[derive(Drop, starknet::Event)]
    struct OwnershipTransferred {
        previous_owner: ContractAddress,
        new_owner: ContractAddress,
    }

    #[embeddable_as(OwnableImpl)]
    impl Ownable<
        TContractState, +HasComponent<TContractState>
    > of IOwnable<ComponentState<TContractState>> {
        fn owner(self: @ComponentState<TContractState>) -> ContractAddress {
            self.owner.read()
        }
        fn transfer_ownership(ref self: ComponentState<TContractState>, new_owner: ContractAddress) {
            assert(!new_owner.is_zero(), 'New owner is the zero address');
            self.assert_only_owner();

            self._transfer_ownership(new_owner);
        }
        fn renounce_ownership(ref self: ComponentState<TContractState>) {
            self.assert_only_owner();

            self._transfer_ownership(Zeroable::zero());
        }
    }

    #[generate_trait]
    impl InternalImpl<
        TContractState, +HasComponent<TContractState>
    > of InternalTrait<TContractState> {
        fn assert_only_owner(self: @ComponentState<TContractState>) {
            let caller = get_caller_address();
            let owner : ContractAddress = self.owner.read();
            assert(!caller.is_zero(), 'Caller is the zero address');
            assert(owner == caller, 'Caller is not the owner');
        }


        fn initializer(ref self: ComponentState<TContractState>, owner: ContractAddress) {
            self._transfer_ownership(owner);
        }

        fn _transfer_ownership(ref self: ComponentState<TContractState>, new_owner: ContractAddress) {
            let previous_owner: ContractAddress = self.owner.read();
            self.owner.write(new_owner);
            self
                .emit(
                    OwnershipTransferred { previous_owner: previous_owner, new_owner: new_owner }
                );
        }

        
    }
}
