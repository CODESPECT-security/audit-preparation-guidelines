# Pre-Audit Checklist — General

Copy this checklist into a GitHub Issue or PR to track your audit preparation.
Chain-specific items are in the dedicated guides:

- [EVM Checklist](./evm/CHECKLIST.md)
- [Solana Checklist](./solana/CHECKLIST.md)

---

## Code Readiness

- [ ] Code compiles without errors or warnings
- [ ] All features are fully implemented — no placeholders or stubs
- [ ] No `TODO`, `FIXME`, or `HACK` comments remain in audited code
- [ ] External dependencies are from reputable, audited sources (no random GitHub repos)
- [ ] Dependency versions are pinned

---

## Documentation

- [ ] Protocol overview document prepared (1–2 pages: what it does, who uses it, why)
- [ ] Architecture diagrams created (contract/program relationships, data flow)
- [ ] Access control matrix defined (who can call what, under what conditions)
- [ ] Known invariants documented (conditions that must always hold true)
- [ ] Known risks and mitigations listed
- [ ] Deployment and upgrade procedures documented

---

## Testing

- [ ] Test coverage meets the minimum threshold for your chain (see chain-specific guide — EVM requires 95% line coverage)
- [ ] End-to-end flow tests cover all primary user journeys
- [ ] Access control tests verify permission boundaries for every privileged action
- [ ] Edge case tests cover zero values, maximum values, and boundary conditions
- [ ] Negative tests verify expected failure conditions (wrong caller, invalid state, insufficient balance)
- [ ] Fuzz or invariant tests implemented (see chain-specific guide for tooling)

---

## Pre-Engagement

- [ ] Deployment scripts prepared and tested on a local or test network
- [ ] Upgrade procedures documented (if protocol is upgradeable)
- [ ] Emergency pause or circuit breaker mechanism implemented
- [ ] Audit scope clearly defined — know exactly which contracts/programs are in scope before the kickoff call
