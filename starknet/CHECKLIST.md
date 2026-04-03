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

- [ ] Doc comments (`///`) present on all public interface functions and trait methods (`# Arguments`, `# Returns`, `# Panics` sections included)
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
- [ ] Every test includes at least 2 meaningful assertions
- [ ] Panic condition tests account for at least 20% of all tests

---

## Security

- [ ] `Pausable` component implemented and tested for emergency stops
- [ ] All privileged functions protected by `Ownable` or `AccessControl`
- [ ] Arithmetic uses typed integers (`u256`, `u128`), not `felt252`, for token amounts
- [ ] Events emitted for all state-changing operations with sufficient indexed fields
- [ ] Multi-sig or timelock configured for privileged operations (if applicable)
- [ ] Zero address validation on all `ContractAddress` parameters received from users or external callers
