# EVM Audit Preparation Guide

← [Back to main guide](../README.md) | [EVM Checklist →](./CHECKLIST.md)

This guide covers EVM-specific preparation requirements for Solidity protocols on Ethereum and compatible chains.

---

## 1. Code Quality Standards

### Solidity Version

Lock your pragma. Floating versions allow compiler behavior to change under you.

```solidity
// ✅ Correct: locked version
pragma solidity 0.8.20;

// ❌ Avoid: floating version
pragma solidity ^0.8.0;
```

Use the latest stable 0.8.x release. Older versions miss security improvements and carry known compiler bugs.

### Naming Conventions

Follow the [Solidity Style Guide](https://docs.soliditylang.org/en/latest/style-guide.html) consistently. Inconsistent naming is a signal of rushed code.

| Element | Convention | Example |
|---|---|---|
| Contracts | PascalCase | `TokenVault` |
| Functions | camelCase | `transferTokens` |
| Constants | UPPER_SNAKE_CASE | `MAX_SUPPLY` |
| Variables | camelCase | `userBalance` |
| Modifiers | camelCase | `onlyOwner` |
| Events & Errors | PascalCase | `TokenTransferred`, `InsufficientBalance` |

### NatSpec Documentation

Every public and external function needs NatSpec. Auditors read comments to understand your intent; a mismatch between comments and implementation is itself a finding.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Note: import paths use OpenZeppelin Contracts v5.
// v4 users: replace "utils/" with "security/" for ReentrancyGuard and Pausable.

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/// @title TokenVault
/// @notice Secure vault for depositing and withdrawing ERC-20 tokens
/// @dev Implements CEI pattern and reentrancy protection throughout.
///      Inherits OpenZeppelin ReentrancyGuard and Pausable.
/// @custom:security-contact audits@codespect.xyz
contract TokenVault is ReentrancyGuard, Pausable {

    /// @notice Deposit tokens into the vault
    /// @dev Transfers tokens from caller to this contract.
    ///      Caller must have approved this contract for `amount` before calling.
    /// @param token Address of the ERC-20 token to deposit
    /// @param amount Number of tokens to deposit (in token's native decimals)
    /// @return shares Number of vault shares minted to the caller
    /// @custom:security Ensure `token` is a trusted, non-rebasing ERC-20.
    ///                  Rebasing tokens will cause share accounting errors.
    function deposit(address token, uint256 amount)
        external
        returns (uint256 shares)
    {
        // Implementation
    }
}
```

Full template: [`examples/natspec-template.sol`](./examples/natspec-template.sol)

---

## 2. Battle-Tested Patterns

Use established patterns. Do not implement reentrancy guards or access control from scratch. OpenZeppelin has battle-tested implementations. Auditors slow down when they see custom reimplementations.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Note: import paths use OpenZeppelin Contracts v5.
// v4 users: replace "utils/" with "security/" for ReentrancyGuard and Pausable.

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title AuditReadyPatterns
/// @notice Demonstrates the four patterns auditors look for first.
contract AuditReadyPatterns is ReentrancyGuard, Pausable, Ownable {

    mapping(address => uint256) public pendingWithdrawals;

    // CEI + ReentrancyGuard: state updated before external call, guard as backstop
    function withdraw() external nonReentrant whenNotPaused {
        uint256 amount = pendingWithdrawals[msg.sender];        // CHECK
        if (amount == 0) revert NothingToWithdraw();

        pendingWithdrawals[msg.sender] = 0;                    // EFFECT

        (bool success,) = msg.sender.call{value: amount}("");  // INTERACT
        if (!success) revert TransferFailed();
    }

    // Pull over push: record pending payments, let recipients pull
    function _recordPayment(address recipient, uint256 amount) internal {
        pendingWithdrawals[recipient] += amount;
        // (emits PaymentRecorded; see full example for event definition)
    }

    // Emergency stop: pause all operations if a vulnerability is discovered
    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    error NothingToWithdraw();
    error TransferFailed();

    constructor() Ownable(msg.sender) {}
}
```

Full example: [`examples/code-patterns.sol`](./examples/code-patterns.sol)

**Why these patterns matter for your audit:**
- **CEI:** Auditors check for violations first. Clean CEI lets them move on faster.
- **ReentrancyGuard:** Eliminates an entire vulnerability class.
- **Pausable:** Shows auditors you have an emergency response plan.
- **Pull over push:** Prevents griefing and simplifies reentrancy analysis.

**Prefer `Ownable2Step` over `Ownable`:** Standard `Ownable` completes ownership transfer in a single transaction, meaning a typo in the new owner address permanently locks the contract. `Ownable2Step` requires the new owner to accept the transfer, making accidents recoverable. Replace `import "@openzeppelin/contracts/access/Ownable.sol"` with `Ownable2Step.sol`.

**Always check `.call()` return values:** A raw `.call{value: ...}("")` that silently fails will appear to succeed while ETH is stuck. The pattern shown in the `withdraw()` example above is correct: capture `(bool success,)` and revert if `!success`. Likewise, never use `address.transfer()` or `address.send()` for ETH; they forward a hard-coded gas stipend that breaks with EIP-1884 and similar changes.

---

## 3. EVM-Specific Considerations

### MEV (Maximal Extractable Value)

Document any function where transaction ordering affects outcomes. Auditors look for:
- Sandwich attack surfaces on swaps or liquidity operations
- Front-running of liquidations or oracle updates
- Back-running of large trades or state changes

If your protocol intentionally accepts MEV exposure, document that explicitly.

### Upgradeability

If your protocol is upgradeable, document:
- Which proxy pattern you use (Transparent Proxy, UUPS, Beacon)
- What the admin can change and what is permanently immutable
- Storage layout: slot assignments and upgrade compatibility

Auditors spend significant time on upgrade paths. Clear layout documentation cuts this time in half.

Two implementation-level requirements auditors check on every upgradeable contract:
- **`_disableInitializers()` in the implementation constructor:** Without this, an attacker can call `initialize()` directly on the bare implementation contract and take control of it. Add `constructor() { _disableInitializers(); }` to every implementation.
- **Storage gaps or ERC-7201 namespaced storage:** Without reserved slots, adding a new storage variable to a base contract in a future upgrade shifts all inheriting contracts' storage and corrupts state. Either reserve `uint256[50] private __gap;` at the end of base contracts, or use OpenZeppelin's ERC-7201 `@custom:storage-location erc7201:...` annotation with `StorageSlot`.

### Oracle Risk

For every price feed or external data source, document:
- The source (Chainlink feed address, TWAP contract, Pyth network, etc.)
- The acceptable staleness window and what happens when it is exceeded
- The consequences of price manipulation: what could an attacker achieve?

When using Chainlink's `latestRoundData()`, validate all relevant return fields — not just the price:

```solidity
(uint80 roundId, int256 price, , uint256 updatedAt, uint80 answeredInRound) = feed.latestRoundData();
require(answeredInRound >= roundId, "Stale price: round not complete");
require(updatedAt >= block.timestamp - MAX_STALENESS, "Price too old");
require(price > 0, "Invalid price");
```

Omitting any of these checks is a common finding. Document your `MAX_STALENESS` value and the rationale for it.

### Cross-Chain Deployments

If deploying to multiple EVM chains, list each target chain and document any behavioral differences: block time assumptions, available precompiles, gas cost differences, and chain-specific quirks.

---

## 4. Testing Requirements

| Metric | Minimum | Target |
|---|---|---|
| Line coverage | 95% | 100% |
| Branch coverage | 90% | 100% |
| Function coverage | 100% | 100% |

**Test categories, all four are required:**

- **Unit tests:** Each function in isolation: happy path, edge cases (0 values, max values, boundaries), revert conditions with correct error messages, event emission verification
- **Integration tests:** Multi-contract workflows, oracle interactions, cross-protocol integrations
- **Fork tests:** Tests against real mainnet state: real oracle prices, real liquidity pools, real deployed contracts
- **Fuzz + invariant tests:** `forge test --fuzz-runs 10000`; invariant tests for critical protocol properties that must hold across all state transitions

---

## 5. Recommended Tools

| Tool | Purpose |
|---|---|
| [Foundry](https://book.getfoundry.sh) | Primary development and testing framework: fast compilation, built-in fuzzing, fork testing |
| [Hardhat](https://hardhat.org) | JavaScript-based environment with extensive plugin ecosystem |
| [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts) | Battle-tested standard implementations. Use these, don't reinvent them. |
| [Solmate](https://github.com/transmissions11/solmate) / [Solady](https://github.com/Vectorized/solady) | Gas-optimized alternatives for performance-critical paths. Prefer Solady for actively maintained contracts. |

---

**Ready for your audit?** → [EVM Pre-Audit Checklist](./CHECKLIST.md)

---

*The automated audit-prep skill used for EVM readiness assessment was originally created by [CD Security](https://cdsecurity.io) and has been extended by CODESPECT.*
