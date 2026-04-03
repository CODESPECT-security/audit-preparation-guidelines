← [Back to main guide](./README.md)

# Pre-Audit Checklist: General

Copy this checklist into a GitHub Issue or PR to track your audit preparation.
Chain-specific items are in the dedicated guides:

- [EVM Checklist](./evm/CHECKLIST.md)
- [Solana Checklist](./solana/CHECKLIST.md)
- [Starknet Checklist](./starknet/CHECKLIST.md)

---

## Code Readiness

- [ ] Code compiles without errors or warnings
- [ ] All features are fully implemented (no placeholders or stubs)
- [ ] No `TODO`, `FIXME`, or `HACK` comments remain in audited code
- [ ] External dependencies are from reputable, audited sources (no random GitHub repos)
- [ ] Dependency versions are pinned

---

## Documentation

- [ ] Protocol overview document prepared (1 to 2 pages: what it does, who uses it, why)
- [ ] Architecture diagrams created (contract/program relationships, data flow)
- [ ] Access control matrix defined (who can call what, under what conditions)
- [ ] Known invariants documented (conditions that must always hold true)
- [ ] `SECURITY.md` created documenting trust assumptions, privileged roles, centralization risks, and known risks
- [ ] `KNOWN_ISSUES.md` created documenting accepted limitations, intentional design trade-offs, and wontfix items
- [ ] `scope.md` created listing in-scope contracts, target chains, and entry points
- [ ] Deployment and upgrade procedures documented

---

## Testing

- [ ] Test coverage meets the minimum threshold
- [ ] End-to-end flow tests cover all primary user journeys
- [ ] Access control tests verify permission boundaries for every privileged action
- [ ] Edge case tests cover zero values, maximum values, and boundary conditions
- [ ] Negative tests verify expected failure conditions (wrong caller, invalid state, insufficient balance)
- [ ] Fuzz or invariant tests implemented (see chain-specific guide for tooling)
- [ ] Every test has at least 2 meaningful assertions (not just a no-revert check)
- [ ] Negative tests (expected failure conditions) account for at least 20% of all tests

---

## Pre-Engagement

- [ ] Deployment scripts prepared and tested on a local or test network
- [ ] Upgrade procedures documented (if protocol is upgradeable)
- [ ] Emergency pause or circuit breaker mechanism implemented
- [ ] Audit scope clearly defined: know exactly which contracts/programs are in scope before the kickoff call
- [ ] Repository is in a clean state: no uncommitted changes to source files before the audit
- [ ] README includes setup instructions so auditors can build and run tests without asking
