// Cairo security patterns for audit-ready Starknet contracts.
//
// This file demonstrates:
// - Safe arithmetic with explicit zero checks
// - Address validation
// - ReentrancyGuard component usage (OpenZeppelin)
// - Pausable component usage (OpenZeppelin)
// - Access control via Ownable
// - Unit test and fuzz test structure

// =============================================================================
// Pattern 1: Safe Arithmetic
//
// Cairo integers (u256, u128, etc.) panic on overflow by default.
// felt252 does NOT — it wraps modulo the field prime.
// Use typed integers (u256, u128) for token amounts and balances.
// Explicit zero checks prevent division-by-zero panics.
// =============================================================================

fn safe_divide(a: u256, b: u256) -> u256 {
    assert(b != 0, 'Division by zero');
    a / b
}

// =============================================================================
// Pattern 2: Address Validation
//
// ContractAddress has an is_zero() method. Always validate addresses
// that come from user input before writing them to storage or transferring funds.
// =============================================================================

fn validate_address(address: starknet::ContractAddress) {
    assert(!address.is_zero(), 'Invalid zero address');
}

// =============================================================================
// Pattern 3: ReentrancyGuard + Pausable (OpenZeppelin components)
//
// Use OpenZeppelin Cairo components — do not implement your own guards.
// Components are composed into contracts using the component! macro.
// Auditors check for missing guards on functions that make external calls.
// =============================================================================

#[starknet::contract]
mod AuditReadyPatterns {
    use openzeppelin::security::reentrancyguard::ReentrancyGuardComponent;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin::access::ownable::OwnableComponent;
    use starknet::ContractAddress;

    component!(path: ReentrancyGuardComponent, storage: reentrancy_guard, event: ReentrancyGuardEvent);
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    impl ReentrancyGuardInternalImpl = ReentrancyGuardComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        pending_withdrawals: starknet::storage::Map<ContractAddress, u256>,
        #[substorage(v0)]
        reentrancy_guard: ReentrancyGuardComponent::Storage,
        #[substorage(v0)]
        pausable: PausableComponent::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        PaymentRecorded: PaymentRecorded,
        ReentrancyGuardEvent: ReentrancyGuardComponent::Event,
        PausableEvent: PausableComponent::Event,
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct PaymentRecorded {
        #[key]
        recipient: ContractAddress,
        amount: u256,
    }

    #[abi(embed_v0)]
    impl AuditReadyImpl of super::IAuditReady<ContractState> {
        // ReentrancyGuard + Pausable: guard external calls, allow emergency stop
        fn withdraw(ref self: ContractState) {
            self.pausable.assert_not_paused();
            self.reentrancy_guard.start();

            let caller = starknet::get_caller_address();
            let amount = self.pending_withdrawals.read(caller);
            assert(amount != 0, 'Nothing to withdraw');

            // Update state BEFORE external call (CEI pattern)
            self.pending_withdrawals.write(caller, 0);

            // External call last
            // (transfer ETH/tokens to caller here)

            self.reentrancy_guard.end();
        }

        // Pull over push: record pending amounts, callers pull their funds
        fn record_payment(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            validate_address(recipient);
            let current = self.pending_withdrawals.read(recipient);
            self.pending_withdrawals.write(recipient, current + amount);
            self.emit(PaymentRecorded { recipient, amount });
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        // Emergency stop: pause all operations if a vulnerability is discovered
        fn pause(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.pausable.pause();
        }

        fn unpause(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.pausable.unpause();
        }
    }
}

// =============================================================================
// Pattern 4: Testing with Starknet Foundry
//
// Use snforge_std for cheatcodes (start_cheat_caller_address, etc.)
// Write both happy-path and panic tests. Use #[fuzzer] for property testing.
// =============================================================================

#[cfg(test)]
mod tests {
    use super::AuditReadyPatterns;
    use starknet::contract_address_const;
    use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address};

    #[test]
    fn test_record_payment_success() {
        // Deploy contract, record a payment, verify pending withdrawal updated
        let recipient = contract_address_const::<'recipient'>();
        // ... deploy and interact
        // assert(contract.pending_withdrawals(recipient) == 100_u256, 'Balance mismatch');
    }

    #[test]
    #[should_panic(expected: ('Invalid zero address',))]
    fn test_record_payment_zero_address() {
        // Zero address should panic
        let zero = contract_address_const::<0>();
        // contract.record_payment(zero, 100_u256); // Should panic
    }

    #[test]
    #[fuzzer(runs: 1000, seed: 42)]
    fn test_fuzz_safe_divide(a: u256, b: u256) {
        if b == 0 {
            return; // Skip zero divisor — tested separately
        }
        let result = super::safe_divide(a, b);
        assert(result <= a, 'Result cannot exceed dividend');
    }
}
