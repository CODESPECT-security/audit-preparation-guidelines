# Multi-Chain audit-prep Skill — Design Spec

**Date:** 2026-04-07
**Status:** Approved
**Scope:** Extend `audit-prep-skills/audit-prep/` to support EVM (Solidity) and Solana (Rust/Anchor), with a clean structure that makes adding future chains (e.g. Starknet) trivial.

---

## Problem

The current `audit-prep` skill is EVM/Solidity-only. All pipeline logic, agent instructions, and checks are hardcoded for Solidity. Adding Solana requires a structural change, not just new files appended to the existing layout.

---

## Goals

- Single `/audit-prep` entry point for all chains
- EVM pipeline unchanged in behavior; restructured in location
- Solana pipeline with 10 phases (8 shared + 2 Solana-specific)
- Adding a third chain (e.g. Starknet) requires only adding `references/chains/starknet/`
- Every file stays under 500 lines

---

## Directory Structure

```
audit-prep/
  SKILL.md                                    ← thin dispatcher (~60 lines)
  VERSION
  references/
    shared-rules.md                           ← unchanged
    chains/
      evm/
        orchestrator.md                       ← current SKILL.md pipeline, moved here
        agents/
          testing-agent.md                    ← moved
          source-analysis-agent.md            ← moved
          infrastructure-agent.md             ← moved
      solana/
        orchestrator.md                       ← new
        agents/
          testing-agent.md                    ← new
          source-analysis-agent.md            ← new
          infrastructure-agent.md             ← new
          account-validation-agent.md         ← new (Phases 9 + 10)
  evals/
    evm/
      evals.json                              ← moved
      grade.sh                               ← moved
    solana/
      evals.json                              ← new
      grade.sh                               ← new
```

---

## SKILL.md — Dispatcher

Responsibilities:
1. Read `VERSION`, print banner (identical to today)
2. Ask chain selection via `AskUserQuestion`: `EVM (Solidity)` | `Solana (Rust/Anchor)` (extensible list)
3. Read `references/chains/<chain>/orchestrator.md` and execute it

All CLI flags (`--fix`, `--report`, `--ci`, `--diff`, `--no-scan`, `--min-score`, `--scanner`) are forwarded to the orchestrator unchanged. No chain-specific logic lives in the dispatcher.

---

## Chain Orchestrators

Both orchestrators follow the same 4-turn structure. The EVM orchestrator is a direct move of the existing `SKILL.md` pipeline logic with agent paths updated. The Solana orchestrator is new.

### Turn 0 — Project Selection (both chains)
The orchestrator asks where the project is (current directory / local path / GitHub URL). The dispatcher has already printed the banner and captured the chain choice before the orchestrator runs.

### Turn 1 — Discover and Prepare

**EVM:** Unchanged. Detects `foundry.toml` / `hardhat.config.*`. Discovers `.sol` files, excludes `test/`, `script/`, `lib/`, `node_modules/`, `interfaces/`, `mocks/`. Creates 3 agent bundles (A, B, C).

**Solana:** Detects `Anchor.toml` / `Cargo.toml`. Discovers `.rs` source files under `programs/` (excludes `tests/`). Discovers test files in `tests/` (`.ts`) and `tests/` (`.rs`). Creates 4 agent bundles (A, B, C, D).

### Turn 2 — Spawn Agents

**EVM:** 3 parallel agents (A, B, C). Unchanged.

**Solana:** 4 parallel agents (A, B, C, D). 4 TaskCreate spinners before spawning.

### Turn 3 — Score and Report

Same report structure for both chains. Phase weights differ (see below). Verdict logic identical.

**Solana override rule:** If Phase 1 (Coverage) < 90, verdict capped at "Almost Ready (coverage below 90%)".

### Turn 4 — Scan Menu

**EVM:** Unchanged (Slither, Aderyn, Pashov Solidity Auditor, custom).

**Solana:** Trident (extended fuzz run beyond Phase 2 estimate), Soteria (if installed), custom scanner. `cargo audit` is NOT listed here — it already runs in Phase 5 and would be redundant.

---

## Solana Agent Responsibilities

### Agent A — Testing (Phases 1 + 2)

**Phase 1 — Test Coverage**
- Run `cargo llvm-cov --summary-only 2>&1` (timeout 300s). If unavailable, estimate from test file matching.
- Match programs in `programs/` against test files in `tests/`.
- Compiler health: `anchor build 2>&1 | grep -ci warning`.
- Scoring: same structure as EVM (base = branch coverage %, -15 per untested program, -10 per compiler warning, cap -30).

**Phase 2 — Test Quality**
- Grep test files for: `it(`, `assert`, `expect`, `should.be.rejected`, Bankrun/Mollusk imports, Trident fuzz harnesses.
- Assertion density threshold: ≥ 2.0 assertions/test.
- Negative test threshold: ≥ 20% of tests.
- Fuzz bonus: +5 if Trident harnesses found.

### Agent B — Source Analysis (Phases 3 + 4 + 6)

**Phase 3 — Documentation**
- Grep `pub fn` instructions and `#[account]` structs for preceding `///` doc comments.
- Check for `# Access Control` and `# Errors` sections per instruction (required per Solana guide).
- Stale param detection: `@param` / `/// * \`name\`` name must match actual parameter.
- Scoring: -3 per undocumented instruction (cap -60), -5 per undocumented account struct (cap -20).

**Phase 4 — Code Hygiene**
- TODO/FIXME/HACK: -3 each (cap -30)
- Direct arithmetic on user values: grep `deposited + amount` / `balance - amount` patterns without `checked_`; -5 each (cap -20)
- `init_if_needed` without inline justification comment: -10
- `msg!` debug logs left in production code: -5 each (cap -15)
- Inconsistent error handling (mix of `panic!` and `Result`): -5

**Phase 6 — Best Practices**
- Raw `AccountInfo` used for state accounts instead of `Account<'info, T>`: -10 each (cap -20)
- Bump not stored on-chain (`bump` field missing from account struct): -5 each (cap -15)
- Missing signer validation on privileged instructions: -10 each (cap -30)
- No emergency pause / circuit breaker on programs holding user funds: -10
- Events not emitted on state-changing instructions: -3 each (cap -30)

### Agent C — Infrastructure (Phases 5 + 7 + 8)

**Phase 5 — Dependencies**
- `cargo audit --json 2>&1`: critical CVE -20, high/moderate -10
- `Cargo.lock` present: missing -10
- `rust-toolchain.toml` committed: missing -15
- Anchor + Solana CLI versions documented in README or Makefile: missing -10

**Phase 7 — Deployment**
- `anchor build` passes: fail -50
- `anchor test` (non-fork) passes: fail -30
- Deploy scripts present (`scripts/`, `migrations/`, `deploy/`): missing -30
- Upgrade authority disposition documented (active key / multisig / burned): missing -20
- README has setup instructions (install, build, test): missing -15

**Phase 8 — Project Documentation**
- Architecture overview: missing -30
- Trust assumptions / SECURITY.md: missing -25
- System invariants: missing -20
- Known issues: missing -15
- Scope definition: missing -10
- Upgrade authority disposition (required for Solana, not conditional): missing -15

### Agent D — Account Validation + CPI Safety (Phases 9 + 10) — Solana-only

**Phase 9 — Account Validation**

| Check | Grep pattern | Deduction |
|-------|-------------|-----------|
| PDA seeds documented | `#[account]` structs missing `/// PDA seeds:` comment | -10 each (cap -30) |
| Bump stored on-chain | `bump` field in account struct | -5 each (cap -15) |
| `init_if_needed` unguarded | `init_if_needed` without constraint verifying not-yet-initialized | -15 each |
| Duplicate mutable accounts | Instructions with 2+ `mut` accounts lacking `constraint` enforcing distinct keys | -10 each (cap -20) |
| Raw AccountInfo for state | `AccountInfo` in `#[derive(Accounts)]` for state-holding accounts | -10 each (cap -20) |

**Phase 10 — CPI Safety**

| Check | Grep pattern | Deduction |
|-------|-------------|-----------|
| Arbitrary CPI | `invoke(` or `invoke_signed(` without preceding `require_keys_eq!` on program ID | -20 each (cap -40) |
| Missing program ID validation | CPI via `CpiContext::new` without `require_keys_eq!` check | -15 each (cap -30) |
| Missing `.reload()` | `CpiContext` call without `.reload()` on any account that CPI may have modified | -10 each (cap -20) |

---

## Phase Weights

| Phase | EVM | Solana |
|-------|-----|--------|
| 1. Test Coverage | 15% | 12% |
| 2. Test Quality | 15% | 12% |
| 3. Documentation | 10% | 8% |
| 4. Code Hygiene | 10% | 8% |
| 5. Dependencies | 10% | 8% |
| 6. Best Practices | 15% | 12% |
| 7. Deployment | 10% | 8% |
| 8. Project Docs | 15% | 12% |
| 9. Account Validation | — | 10% |
| 10. CPI Safety | — | 10% |
| **Total** | **100%** | **100%** |

---

## Shared Rules

`references/shared-rules.md` is unchanged. Both chains use the same `PHASE/FAIL/PASS` output format, the same DO NOT rules (no gas, no vuln analysis, no prose), and the same scope exclusions.

---

## Evals

EVM evals move to `evals/evm/`. Solana evals target two project archetypes:
- A minimal Anchor project (single program, basic deposit/withdraw)
- An Anchor project with CPI calls and multiple programs

---

## Out of Scope

- Starknet support (guides exist; skill to follow same pattern)
- Auto-fix (`--fix`) for Solana — deferred; EVM auto-fix unchanged
- Score comparison across chains (scores are per-chain only)
