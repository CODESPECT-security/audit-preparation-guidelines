# Pre-Audit Checklist: EVM (Solidity)

Complete all items in the [General Pre-Audit Checklist](../CHECKLIST.md) first,
then work through the EVM-specific items below.

---

## Code Readiness

- [ ] Solidity version is locked (`pragma solidity 0.8.x;`, no floating `^`)
- [ ] Code compiles with zero warnings at the locked version
- [ ] OpenZeppelin contracts are updated to the latest stable version
- [ ] No use of `tx.origin` for authorization
- [ ] All `unchecked` blocks are justified with inline comments explaining why overflow is impossible
- [ ] Every source file has a `// SPDX-License-Identifier:` header
- [ ] All `.call()` return values checked: `(bool success,) = ...` with explicit revert on failure
- [ ] No `address.transfer()` or `address.send()` used for ETH (use `.call{value: ...}("")` with a success check instead)

---

## Documentation

- [ ] NatSpec complete on all public and external functions (`@title`, `@notice`, `@dev`, `@param`, `@return`)
- [ ] Custom errors documented with `@notice` explaining when they are thrown
- [ ] Upgradeability pattern documented (Transparent Proxy, UUPS, Beacon, or none)
- [ ] Admin capabilities and their limitations documented (what can the owner change?)
- [ ] Oracle dependencies listed (Chainlink feeds, TWAPs, Pyth, etc.) with staleness thresholds
- [ ] MEV exposure assessed: sandwich attacks, front-running of liquidations, back-running of large trades
- [ ] Cross-chain deployment targets listed (if applicable) with any chain-specific behavioral differences

---

## Testing

- [ ] Line coverage ≥ 95%
- [ ] Branch coverage ≥ 90%
- [ ] Function coverage = 100%
- [ ] Integration tests cover multi-contract workflows
- [ ] Fork tests run against mainnet state (real oracles, real liquidity, real deployed contracts)
- [ ] Foundry fuzz tests implemented (`forge test --fuzz-runs 10000`)
- [ ] Invariant tests written and passing for all critical protocol invariants

---

## Security

- [ ] `ReentrancyGuard` applied to all functions making external calls or transferring value
- [ ] Checks-Effects-Interactions pattern followed throughout (state updated before external calls)
- [ ] Multi-sig or timelock configured for privileged operations (if applicable)
- [ ] Emergency pause mechanism implemented and covered by tests
- [ ] Proxy storage layout verified: no slot collisions between implementation versions
- [ ] Events emitted for all state-changing operations
- [ ] `Ownable2Step` used instead of `Ownable` where ownership transfer is possible (two-step transfer prevents sending ownership to an uncontrolled address)
- [ ] Zero-address validation on all critical `address` constructor parameters and setter functions
- [ ] Oracle staleness validated after `latestRoundData()`: `updatedAt` within acceptable window and `answeredInRound >= roundId`
- [ ] Upgradeable implementation contracts call `_disableInitializers()` in constructor (if applicable)
- [ ] Upgradeable base contracts define storage gaps (`uint256[50] private __gap`) or use ERC-7201 namespaced storage (if applicable)
