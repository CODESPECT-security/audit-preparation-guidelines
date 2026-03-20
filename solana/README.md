# Solana Audit Preparation Guide

← [Back to main guide](../README.md) | [Solana Checklist →](./CHECKLIST.md)

This guide covers Solana-specific preparation requirements for programs written in Rust with the Anchor framework.

> **Note:** Solana on-chain code is officially called a *program*. This guide uses *smart contract* and *program* interchangeably.

---

## 1. Code Quality Standards

### Naming Conventions

Consistent naming is a signal of code quality. Auditors reading well-named code make fewer mistakes.

| Element | Convention | Example |
|---|---|---|
| Functions / instructions | `snake_case` | `transfer_tokens` |
| Structs / account types | `PascalCase` | `UserVault` |
| Constants | `SCREAMING_SNAKE_CASE` | `MAX_SUPPLY` |
| Variables | `snake_case` | `user_balance` |
| Error variants | `PascalCase` | `Unauthorized`, `ZeroAmount` |

### Toolchain Version

Pin your Rust, Anchor, and Solana CLI versions. Floating toolchains affect reproducibility — if the auditor's environment differs from yours, compilation or test results may differ too.

Use `rust-toolchain.toml` to pin Rust:

```toml
[toolchain]
channel = "1.79.0"
```

Pin Anchor and Solana CLI versions in your project README or `Makefile`:

```bash
# Reproduce the exact environment
anchor --version   # anchor-cli 0.30.x
solana --version   # solana-cli 1.18.x
```

Commit `rust-toolchain.toml` to your repository. Auditors will use it.

### Documentation Comments

Every instruction and public account struct needs documentation comments. Auditors read these to understand your intent — a mismatch between comments and implementation is a finding.

```rust
/// Transfer tokens from the user's vault to a recipient.
///
/// # Access Control
/// Only the vault owner (signer) can initiate a transfer.
///
/// # Errors
/// - `VaultError::Unauthorized` if signer is not the vault owner
/// - `VaultError::InsufficientFunds` if vault balance < amount
/// - `VaultError::ZeroAmount` if amount == 0
pub fn transfer(ctx: Context<Transfer>, amount: u64) -> Result<()> {
    // implementation
}
```

---

## 2. Account Structure

Document every account type before your audit. Auditors spend a significant share of their time tracing account ownership and PDA derivation. Clear, upfront documentation reduces this to minutes instead of hours.

For each account type, document: fields and their purpose, PDA seeds and derivation logic, account lifecycle (creation, valid state transitions, closure), and size calculation.

```rust
use anchor_lang::prelude::*;

/// Per-user vault storing deposit state.
///
/// PDA seeds: `["vault", user.key()]`
/// Size: `UserVault::LEN` bytes
#[account]
#[derive(Default)]
pub struct UserVault {
    /// The owner of this vault. Only this address can deposit or withdraw.
    pub owner: Pubkey,   // 32 bytes

    /// Total lamports deposited.
    pub deposited: u64,  // 8 bytes

    /// Bump seed for PDA validation. Stored to avoid recomputation.
    pub bump: u8,        // 1 byte
}

impl UserVault {
    /// Discriminator (8) + owner (32) + deposited (8) + bump (1)
    pub const LEN: usize = 8 + 32 + 8 + 1;
}

/// Deposit instruction accounts.
/// Seeds + bump verify the correct PDA. Constraint verifies ownership.
#[derive(Accounts)]
pub struct Deposit<'info> {
    #[account(
        mut,
        seeds = [b"vault", user.key().as_ref()],
        bump = vault.bump,
        constraint = vault.owner == user.key() @ VaultError::Unauthorized,
    )]
    pub vault: Account<'info, UserVault>,

    #[account(mut)]
    pub user: Signer<'info>,

    pub system_program: Program<'info, System>,
}
```

Full example with instruction handler and error definitions: [`examples/account-structure.rs`](./examples/account-structure.rs)

---

## 3. Solana-Specific Considerations

These are the vulnerability classes Solana auditors check first. Understanding them helps you write code that is fast to audit — and harder to exploit.

### CPI (Cross-Program Invocation) Risks

**Arbitrary CPI:** Always validate program IDs before invoking via CPI. An attacker can pass a malicious program that satisfies your account constraints but executes different logic.

```rust
// ✅ Validate program ID explicitly
require_keys_eq!(
    ctx.accounts.token_program.key(),
    anchor_spl::token::ID,
    VaultError::InvalidProgram
);
```

**Account reloading:** Accounts modified through CPI are not automatically refreshed in your program's memory. Always call `.reload()` before reading an account that was modified by a CPI call.

```rust
anchor_spl::token::transfer(cpi_ctx, amount)?;
ctx.accounts.vault.reload()?;  // Required — CPI may have changed vault state
```

### Missing Ownership Checks

Anchor's `Account<'info, T>` automatically verifies account ownership. Raw `AccountInfo` does not. Avoid raw `AccountInfo` for accounts that hold program state.

### Reinitialization

Use Anchor's `init` constraint — not `init_if_needed` — unless reinitialization is explicitly part of your design. Reinitializing an account can reset state that should be permanent.

### Duplicate Mutable Accounts

If the same account appears in two mutable positions, Solana's runtime may produce unexpected results. Use Anchor `constraint` checks to enforce that mutable accounts are distinct where required.

### Arithmetic

Never use unchecked arithmetic on user-controlled values.

```rust
// ✅ Checked — returns an error on overflow
let new_balance = vault.deposited
    .checked_add(amount)
    .ok_or(VaultError::Overflow)?;

// ❌ Panics on overflow in debug, wraps silently in release
let new_balance = vault.deposited + amount;
```

### Upgrade Authority

Every Solana program has an upgrade authority — the keypair that can modify the deployed bytecode. Auditors always ask about it. Have a clear answer.

Document your program's upgrade authority disposition:

- **Active upgrade key** — Who holds it? Is it a multisig? What is the threshold?
- **Timelock** — Is there a delay between proposing and executing an upgrade?
- **Immutable** — Have you burned the upgrade authority? If so, document when and provide the transaction signature.

An undocumented or unrevoked upgrade authority is a common audit finding. If your protocol is intended to be immutable, burn the authority before the audit or state explicitly that this will happen at launch.

---

## 4. Testing Requirements

| Metric | Minimum | Target |
|---|---|---|
| Line coverage | 90% | 100% |
| Branch coverage | 85% | 100% |
| Critical instructions | 100% | 100% |

**Test categories — all five are required:**

- **E2E flow tests** — Complete user journeys: account creation, deposit, withdrawal, closure. Test the happy path as a real user would experience it.
- **Access control tests** — Every privileged instruction must be tested with an unauthorized caller and confirmed to reject.
- **Edge case tests** — Zero values, maximum `u64`, empty states, accounts at minimum rent, boundary conditions.
- **Negative tests** — Invalid signers, wrong account ownership, closed accounts, PDAs with incorrect seeds, replay attempts.
- **Fuzz / invariant tests** — Property-based testing via Trident. Define invariants (e.g., total deposited ≤ vault balance) and verify they hold under arbitrary inputs.

---

## 5. Recommended Tools

| Tool | Purpose |
|---|---|
| [Anchor](https://www.anchor-lang.com) | Primary Solana development framework — account constraints, CPI helpers, IDL generation |
| [Trident](https://ackee.xyz/trident/docs) | Fuzz testing framework for Anchor programs |
| [Bankrun](https://github.com/kevinheavey/solana-bankrun) | Fast in-process test runner — significantly faster than spinning up a local validator |
| [Mollusk](https://github.com/buffalojoec/mollusk) | Low-level instruction testing framework — useful for precise account state assertions |
| [Solana CLI](https://docs.solana.com/cli) | Local validator, deployment, account inspection |
| Rust Analyzer | IDE support for Rust — essential for navigating Anchor's macro-heavy codebase |

---

**Ready for your audit?** → [Solana Pre-Audit Checklist](./CHECKLIST.md)
