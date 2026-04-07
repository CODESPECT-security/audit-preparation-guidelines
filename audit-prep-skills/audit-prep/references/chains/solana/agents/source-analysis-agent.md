# Solana Source Analysis Agent: Phases 3, 4 and 6

You have: project_dir, in-scope file list (.rs files), and Grep + Read tools.

**CRITICAL: Do NOT read all source files at once. Use targeted Grep queries for each check.**

## Phase 3: Documentation (8%)

### Step 1: Count documentable elements
Run these Greps on in-scope files:

a) Public instruction functions:
   Pattern: `pub fn \w+.*Context<`
   Count total matches.

b) Account structs:
   Pattern: `#\[account\]`
   Count total matches.

c) Error enums:
   Pattern: `#\[error_code\]`

### Step 2: Count doc comment coverage
a) Doc comments on instructions: `///` within 3 lines above `pub fn`
   Pattern: `/// ` (look for presence before each instruction)

b) `# Access Control` sections:
   Pattern: `# Access Control`

c) `# Errors` sections:
   Pattern: `# Errors`

### Step 3: Spot-check gaps
Grep: `pub fn \w+.*Context<` with -B5 context.
Scan for functions not preceded by `///` lines.
Report first 10 undocumented instructions only.

### Step 4: Account struct documentation
Grep: `#\[account\]` with -A20 context.
For each account struct, check that:
- A `/// PDA seeds:` comment exists (if the account is a PDA — seeds present in Accounts struct)
- Field-level doc comments exist for each `pub` field

Deduction: -5 per undocumented account struct (cap -20).

### Scoring
- Base = (documented_instructions / total_instructions) * 100
- Each undocumented instruction: -5 (cap -50)
- Each undocumented account struct: -5 (cap -20)
- Missing `# Access Control` section on instruction: -3 (cap -15)
- Missing `# Errors` section on instruction: -3 (cap -15)

### Output per finding:
```
FAIL | missing_doc | -5 | programs/vault/src/lib.rs:45
desc: transfer() instruction has no doc comment
fix: Add /// doc comment with # Access Control and # Errors sections above the function

FAIL | missing_account_doc | -5 | programs/vault/src/state.rs:12
desc: UserVault account struct has no PDA seeds documentation
fix: Add /// PDA seeds: ["vault", user.key()] comment above the struct
```

## Phase 4: Code Hygiene (8%)

Run each Grep on in-scope source files:

### Check 1: TODO/FIXME/HACK/XXX
Pattern: `TODO|FIXME|HACK|XXX`
Deduction: -3 each (cap -30)

### Check 2: Debug msg! logs
Pattern: `msg!\s*\(`
For each match, read 1 line of context. Flag if the message looks like debug output ("debug", "test", "TODO", or very verbose).
Deduction: -3 each (cap -15)
Note: meaningful program logs are fine; only flag obvious debug noise.

### Check 3: Direct arithmetic on user-controlled values
Pattern: `\w+\s*\+\s*\w+|\w+\s*-\s*\w+|\w+\s*\*\s*\w+`
Check: for each arithmetic operation in instruction handlers (not in `impl` or constants), look for `checked_add\|checked_sub\|checked_mul\|saturating_` nearby.
Deduction: -5 per unchecked operation on user values (cap -20)
Skip arithmetic in `#[constant]` or known-bounded contexts.

### Check 4: `init_if_needed` without justification
Pattern: `init_if_needed`
For each match, read 3 lines above. If no comment explains why reinitialization is safe, flag it.
Deduction: -10 each

### Check 5: Commented-out code
Pattern: `^\s*//\s*(pub fn |let |if |for |while |return )`
Count blocks of 3+ consecutive commented lines nearby.
Deduction: -2 per block (cap -20)

### Check 6: Inconsistent error handling
Grep for `panic!\|unwrap()\|expect("`:
- `panic!` or `unwrap()` in instruction handlers (not in tests/ or build scripts)
- Deduction: -5 each (cap -20)
Instruction handlers must use `Result<()>` and `?` or explicit error returns.

## Phase 6: Best Practices (12%)

### B1: Raw AccountInfo for state accounts
Grep: `AccountInfo<'info>` in `#[derive(Accounts)]` structs.
For each match, read 5 lines of context. If the AccountInfo is used to hold program-owned state (not a system program or sysvar), flag it.
Deduction: -10 each (cap -20)
Anchor's `Account<'info, T>` automatically checks ownership; raw `AccountInfo` does not.

### B2: Bump not stored on-chain
Grep: `seeds = \[` (PDA declarations).
For each PDA account struct, check if a `bump: u8` field exists in the account struct.
Deduction: -5 each (cap -15)
Storing the bump prevents recomputation and protects against bump-grinding attacks.

### B3: Missing signer validation on privileged instructions
Grep: `pub fn \w+.*Context<` for instructions that modify protocol state (set_*, withdraw, pause, update_*, close).
For each, check for `Signer<'info>` in the Accounts struct or an `#[access_control(...)]` attribute.
Deduction: -10 each (cap -30)

### B4: No emergency pause on programs holding user funds
Grep: `pub fn deposit\|pub fn stake\|pub fn lock` in instruction handlers.
If found, check for a `paused` field in config accounts or an `is_paused` check.
Deduction: -10 if missing

### B5: Missing events on state-changing instructions
Grep: `pub fn \w+.*Context<` with -A20 context.
Check for `emit!` in instruction bodies that modify state.
Only flag instructions clearly modifying protocol state (not view/read instructions).
Deduction: -3 each (cap -30)

### B6: Upgrade authority not documented
Grep in README, SECURITY.md, or docs/: `upgrade.authority\|upgrade_authority\|program.*upgradeable\|immutable`
If not found, flag it. Upgrade authority disposition is always required for Solana programs.
Deduction: -15 if undocumented

## Constraints
- Use Grep and Read ONLY; no Bash commands
- Do NOT read all source files at once; use targeted queries
- Do NOT perform vulnerability analysis or threat modeling
- Do NOT flag gas/compute optimizations
- Output ONLY the structured PHASE/FAIL/PASS format
