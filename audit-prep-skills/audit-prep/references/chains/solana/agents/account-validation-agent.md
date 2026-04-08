# Solana Account Validation + CPI Safety Agent: Phases 9 and 10

You have: project_dir, in-scope file list (.rs files), and Grep + Read tools.

**CRITICAL: Do NOT read all source files at once. Use targeted Grep queries for each check.**

## Phase 9: Account Validation (10%)

### A1: PDA seeds undocumented
Grep: `seeds = \[` in `#[derive(Accounts)]` structs.
For each PDA declaration found, check for a `/// PDA seeds:` comment in the corresponding account struct definition.
Deduction: -10 per undocumented PDA (cap -30)
Auditors must be able to verify PDA derivation without reading all callsites.

### A2: Bump not stored on-chain
Grep: `seeds = \[` to find PDA accounts.
For each PDA account, check if the corresponding account struct has a `pub bump: u8` field.
Deduction: -5 per PDA without stored bump (cap -15)
Without a stored bump, programs must recompute it on every instruction, and bump-grinding attacks become possible.

### A3: `init_if_needed` without reinitialization guard
Grep: `init_if_needed`
For each match, read 10 lines of context (the full accounts struct constraint block).
If no `constraint` verifying the account is not already initialized is present, flag it.
Deduction: -15 each
`init_if_needed` without a guard allows an attacker to reinitialize an account and reset its state.

### A4: Duplicate mutable accounts (missing distinct-key constraint)
Grep: Instructions with 2 or more `mut` accounts of the same type.
Pattern: find `#[derive(Accounts)]` blocks with 2+ `#[account(mut` annotations.
For each such instruction, check for a `constraint = account_a.key() != account_b.key()` guard.
Deduction: -10 per instruction missing the distinct-key constraint (cap -20)

### A5: Raw AccountInfo for state accounts
Grep: `AccountInfo<'info>` in `#[derive(Accounts)]` structs.
For each match, read 5 lines of context. If used for program-owned state (not system_program, token_program, rent, or clock sysvars), flag it.
Deduction: -10 each (cap -20)
Anchor's `Account<'info, T>` performs automatic owner and discriminator checks. Raw `AccountInfo` does neither.

### Output:
```
PHASE 9 | Account Validation | SCORE: 60/100

FAIL | missing_pda_docs | -10 | programs/vault/src/state.rs:15
desc: UserVault PDA has no /// PDA seeds: comment
fix: Add /// PDA seeds: ["vault", user.key()] above the UserVault struct

FAIL | bump_not_stored | -5 | programs/vault/src/state.rs:15
desc: UserVault PDA does not store bump seed
fix: Add pub bump: u8 field to UserVault and populate it during init

FAIL | init_if_needed_unguarded | -15 | programs/vault/src/lib.rs:88
desc: init_if_needed used without a not-already-initialized constraint
fix: Add constraint = vault.deposited == 0 @ VaultError::AlreadyInitialized, or use init instead

PASS | no_duplicate_mutable_accounts
note: No instructions found with duplicate mutable accounts of the same type

END PHASE 9
```

## Phase 10: CPI Safety (10%)

### C1: Arbitrary CPI (no program ID validation)
Grep: `invoke\s*\(` and `invoke_signed\s*\(`
For each match, read 10 lines above. Check for `require_keys_eq!` or `if ctx.accounts.<program>.key() !=` validating the program ID before the invoke call.
Deduction: -20 each (cap -40)
Without program ID validation, an attacker can pass a malicious program that satisfies account constraints but executes different logic.

### C2: Missing program ID validation on CPI via CpiContext
Grep: `CpiContext::new\|CpiContext::new_with_signer`
For each match, read 10 lines above. Check for `require_keys_eq!` on the program account key.
If the target program is a well-known Anchor program imported directly (e.g., `anchor_spl::token::transfer`), skip this check (the import already pins the program ID).
Only flag cases where the program account comes from `ctx.accounts.*`.
Deduction: -15 each (cap -30)

### C3: Missing `.reload()` after CPI
Grep: `CpiContext::new\|invoke\s*\(` for CPI calls.
For each CPI call, read 15 lines after. Check for `.reload()` on any account that the CPI may have modified.
Flag only if the same account is READ after the CPI in the same instruction (i.e., stale data would cause incorrect behavior).
Deduction: -10 each (cap -20)

### Output:
```
PHASE 10 | CPI Safety | SCORE: 70/100

FAIL | arbitrary_cpi | -20 | programs/vault/src/lib.rs:112
desc: invoke() called without validating program ID beforehand
fix: Add require_keys_eq!(ctx.accounts.target_program.key(), expected::ID, VaultError::InvalidProgram) before invoke()

FAIL | missing_reload | -10 | programs/vault/src/lib.rs:130
desc: vault account read after CPI but .reload() not called
fix: Add ctx.accounts.vault.reload()? after the CpiContext call at line 128

PASS | no_cpi_context_arbitrary
note: All CpiContext calls use imported Anchor program IDs (anchor_spl::token)

END PHASE 10
```

## Constraints
- Use Grep and Read ONLY; no Bash commands
- Do NOT read all source files at once; use targeted queries
- Do NOT perform broader vulnerability analysis or threat modeling
- Output ONLY the structured PHASE/FAIL/PASS format
