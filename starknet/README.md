# Starknet (Cairo) Audit Preparation Guide

← [Back to main guide](../README.md) | [Starknet Checklist →](./CHECKLIST.md)

This guide covers Starknet-specific preparation requirements for contracts written in Cairo.

---

## 1. Code Quality Standards

### Cairo Edition and Toolchain

Pin your Cairo edition and dependency versions in `Scarb.toml`. Floating versions affect reproducibility — if your auditor's environment differs from yours, compilation results may differ.

```toml
# Scarb.toml
[package]
name = "my_protocol"
version = "0.1.0"
edition = "2024_07"

[dependencies]
starknet = ">=2.8.0"
openzeppelin = { git = "https://github.com/OpenZeppelin/cairo-contracts.git", tag = "v0.17.0" }
```

Commit `Scarb.toml` and `Scarb.lock` to your repository. Auditors will use them to reproduce your exact environment.

### Naming Conventions

Consistent naming is a signal of code quality. Follow Cairo conventions throughout.

| Element | Convention | Example |
|---|---|---|
| Modules | `snake_case` | `token_vault` |
| Contracts / Traits | `PascalCase` | `ITokenVault`, `TokenVault` |
| Functions | `snake_case` | `transfer_tokens` |
| Constants | `UPPER_SNAKE_CASE` | `MAX_SUPPLY` |
| Variables | `snake_case` | `user_balance` |
| Storage variables | `snake_case` | `total_supply` |
| Events | `PascalCase` | `TokenTransferred` |

### Documentation Comments

Every public function and interface method needs documentation comments. Auditors read these to understand your intent — a mismatch between comments and implementation is a finding.

```cairo
/// Transfers tokens from the caller to a recipient.
///
/// # Arguments
/// * `recipient` - The address receiving the tokens
/// * `amount` - The amount of tokens to transfer (u256)
///
/// # Returns
/// * `bool` - True if transfer succeeded
///
/// # Panics
/// * `'Insufficient balance'` - If caller has insufficient balance
/// * `'Invalid zero address'` - If recipient is the zero address
fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
    // Implementation
}
```

Full template: [`examples/doc-template.cairo`](./examples/doc-template.cairo)

---

## 2. Battle-Tested Patterns

Use OpenZeppelin Cairo components — do not implement your own guards. Auditors slow down when they see custom reimplementations of security primitives.

```cairo
#[starknet::contract]
mod AuditReadyPatterns {
    use openzeppelin::security::reentrancyguard::ReentrancyGuardComponent;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin::access::ownable::OwnableComponent;

    // Compose components — each adds storage, events, and implementations
    component!(path: ReentrancyGuardComponent, storage: reentrancy_guard, event: ReentrancyGuardEvent);
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl AuditReadyImpl of super::IAuditReady<ContractState> {
        fn withdraw(ref self: ContractState) {
            self.pausable.assert_not_paused();   // Pausable guard
            self.reentrancy_guard.start();        // Reentrancy guard

            let caller = starknet::get_caller_address();
            let amount = self.pending_withdrawals.read(caller);
            assert(amount != 0, 'Nothing to withdraw');

            self.pending_withdrawals.write(caller, 0); // State update BEFORE external call (CEI)
            // external call here

            self.reentrancy_guard.end();
        }
    }
}
```

Full example: [`examples/cairo-patterns.cairo`](./examples/cairo-patterns.cairo)

**Why these patterns matter for your audit:**
- **ReentrancyGuard** — Cairo contracts can make external calls; reentrancy is a real risk.
- **Pausable** — Shows auditors you have an emergency response plan.
- **CEI (Checks-Effects-Interactions)** — Update state before external calls even with the guard.
- **Pull over push** — Record pending amounts; let callers withdraw rather than pushing funds.

---

## 3. Cairo-Specific Considerations

### felt252 vs Typed Integers

`felt252` is Cairo's native field element. It wraps silently on overflow (modulo the field prime ~2^251). Never use `felt252` for token amounts, balances, or any value where overflow would be incorrect.

```cairo
// ✅ Use typed integers for amounts — overflow panics explicitly
let new_balance: u256 = current_balance + amount;

// ❌ Avoid felt252 for amounts — wraps silently at field prime
let new_balance: felt252 = current_balance_felt + amount_felt;
```

Use `u256` for token amounts, `u128` for intermediate calculations where the range is known.

### Address Validation

Always validate `ContractAddress` inputs from users. The zero address is a common source of stuck funds.

```cairo
fn validate_address(address: ContractAddress) {
    assert(!address.is_zero(), 'Invalid zero address');
}
```

### L1-L2 Messaging

If your protocol uses Starknet's L1-L2 messaging, document:
- Which L1 contracts send messages to your Starknet contract
- Which L1 handler functions process those messages
- How replay protection is implemented (Starknet's runtime does not prevent replay by default — your contract must)
- What happens if a message is consumed out of order

### Upgrade Authority

Document your contract's upgradeability status:
- **Upgradeable** — Who controls the upgrade? Is there a timelock? What is the multisig threshold?
- **Immutable** — State this explicitly. Auditors will verify there is no upgrade entrypoint.

An undocumented upgrade entrypoint is a common finding. Decide and document before the audit.

### Sequencer Assumptions

Do not rely on `starknet::get_block_timestamp()` for critical ordering logic. Sequencers can manipulate timestamps within a range. Use on-chain block numbers or external price feeds with staleness checks instead.

---

## 4. Testing Requirements

| Metric | Minimum | Target |
|---|---|---|
| Line coverage | 95% | 100% |
| Branch coverage | 90% | 100% |
| Function coverage | 100% | 100% |

**Test categories — all four are required:**

- **Unit tests** — Each function in isolation: happy path, edge cases (0, max `u256`), all panic conditions with correct messages, event emission verification
- **Integration tests** — Multi-contract workflows, oracle (Pragma) interactions, L1-L2 message flows
- **Fork tests** — Tests against real Starknet mainnet or Sepolia state (Starknet Foundry forking)
- **Fuzz tests** — `#[fuzzer(runs: 1000)]` on critical mathematical functions; invariant tests for protocol properties

Full test examples: [`examples/cairo-patterns.cairo`](./examples/cairo-patterns.cairo)

---

## 5. Recommended Tools

| Tool | Purpose |
|---|---|
| [Scarb](https://docs.swmansion.com/scarb) | Official Cairo package manager and build tool — required for any Cairo project |
| [Starknet Foundry](https://foundry-rs.github.io/starknet-foundry) | Testing framework with fuzzing, forking, and cheatcodes (`snforge`) |
| [OpenZeppelin Cairo](https://docs.openzeppelin.com/contracts-cairo) | Battle-tested component implementations (ERC20, AccessControl, ReentrancyGuard, Pausable) |
| [Alexandria](https://github.com/keep-starknet-strange/alexandria) | Community Cairo utility library — data structures, math, and more |

---

**Ready for your audit?** → [Starknet Pre-Audit Checklist](./CHECKLIST.md)
