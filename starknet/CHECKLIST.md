# Pre-Audit Checklist: Starknet (Cairo)

Complete all items in the [General Pre-Audit Checklist](../CHECKLIST.md) first,
then work through the Cairo/Starknet-specific items below.

---

## Code Readiness

- [ ] Cairo edition locked in `Scarb.toml` (e.g., `edition = "2024_07"`)
- [ ] `scarb build` completes without errors or warnings
- [ ] OpenZeppelin Cairo contracts pinned to a specific version tag
- [ ] No TODO or FIXME comments remain
- [ ] All external dependencies use official sources (not unverified forks)

---

## Documentation

- [ ] Protocol overview prepared (1 to 2 pages: what it does, who uses it, why)
- [ ] Architecture diagrams created (component hierarchy, dispatcher relationships)
- [ ] Access control matrix defined (roles: owner, admin, pauser; what each can do)
- [ ] Known invariants documented (conditions that must always hold true)
- [ ] Known risks and mitigations listed
- [ ] L1-L2 messaging flows documented (if applicable)
- [ ] Upgradeability policy stated: upgradeable or immutable, and by whom

---

## Testing

- [ ] Line coverage ≥ 95%
- [ ] Branch coverage ≥ 90%
- [ ] Function coverage = 100%
- [ ] Unit tests cover happy path, edge cases (0, max values), and all panic conditions
- [ ] Integration tests cover multi-contract workflows and oracle interactions
- [ ] Fork tests run against Starknet mainnet/Sepolia state (Starknet Foundry)
- [ ] Fuzz tests implemented (`#[fuzzer(runs: 1000)]`) for critical mathematical functions
- [ ] Invariant tests written for critical protocol properties

---

## Security

- [ ] `ReentrancyGuard` component applied to functions making external calls
- [ ] `Pausable` component implemented and tested for emergency stops
- [ ] All privileged functions protected by `Ownable` or `AccessControl`
- [ ] `ContractAddress` inputs validated with `.is_zero()` checks
- [ ] Arithmetic uses typed integers (`u256`, `u128`), not `felt252`, for token amounts
- [ ] Events emitted for all state-changing operations with sufficient indexed fields
- [ ] Multi-sig or timelock configured for privileged operations (if applicable)

---

## Cairo-Specific Vulnerabilities: Review Before Submitting

- [ ] **felt252 arithmetic:** No token amounts or balances stored as `felt252` (wraps silently)
- [ ] **Storage collisions:** No storage slot collisions in upgradeable contracts
- [ ] **Reentrancy:** `ReentrancyGuard` applied to all external call paths
- [ ] **Zero address:** All `ContractAddress` inputs validated as non-zero
- [ ] **L1-L2 message replay:** L1 handler messages cannot be replayed (if applicable)
- [ ] **Account abstraction:** Signature validation correct in account contracts (if applicable)
- [ ] **Dispatcher safety:** Cross-contract call failures are handled, not silently swallowed
- [ ] **Sequencer assumptions:** No critical logic depends on block timestamp ordering
- [ ] **Storage packing:** No unintended storage slot sharing in component composition
