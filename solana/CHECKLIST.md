# Pre-Audit Checklist — Solana (Rust/Anchor)

Complete all items in the [General Pre-Audit Checklist](../CHECKLIST.md) first,
then work through the Solana-specific items below.

---

## Code Readiness

- [ ] `anchor build` completes without errors or warnings
- [ ] Toolchain versions pinned (`rust-toolchain.toml` committed, Anchor and Solana CLI versions documented)
- [ ] All account constraints are explicit — no implicit trust
- [ ] No TODO or placeholder instructions remain
- [ ] PDA seeds are deterministic and documented for every account type

---

## Documentation

- [ ] Instruction flow diagrams (or documented flow descriptions) created for each program instruction (purpose, caller, preconditions, state changes)
- [ ] Account structure documented for each account type: fields, size calculation, PDA derivation, lifecycle, and rent exemption
- [ ] CPI (Cross-Program Invocation) interactions documented — which programs are called and under what conditions
- [ ] Privileged roles defined: upgrade authority, admin, pauser, and their capabilities
- [ ] State machine diagram provided if the program has complex state transitions

---

## Testing

- [ ] Line coverage ≥ 90% of code paths
- [ ] Critical instructions have 100% test coverage
- [ ] Branch coverage ≥ 85% (measurable with `cargo llvm-cov`)
- [ ] E2E tests cover complete user flows (account creation → deposit → withdrawal → close)
- [ ] Access control tests verify every privileged instruction rejects unauthorized callers
- [ ] Tests verify correct PDA derivation and rejection of PDAs with incorrect seeds
- [ ] Negative tests: invalid signers, wrong account ownership, closed accounts, replay attempts
- [ ] Fuzzing implemented via Trident or equivalent

---

## Security

- [ ] All account ownership checks are explicit (Anchor `Account<'info, T>` verifies ownership automatically; raw `AccountInfo` does not)
- [ ] CPI program IDs validated before invocation (no arbitrary CPI)
- [ ] Accounts modified via CPI are reloaded before further use (`.reload()`)
- [ ] Duplicate mutable accounts checked — same account not passed in two mutable positions
- [ ] Reinitialization prevented — accounts verify they are not already initialized
- [ ] All arithmetic uses checked operations (`checked_add`, `checked_mul`, etc.) with explicit error handling
