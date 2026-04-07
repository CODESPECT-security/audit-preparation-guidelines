# CLAUDE.md

Instructions for Claude when working in this repository.

---

## What This Repo Is

**CODESPECT Audit Preparation Guides** — a public knowledge base and tooling library that helps smart contract development teams prepare their codebases for professional security audits. The goal is to eliminate wasted audit time on orientation work (documentation gaps, missing tests, code hygiene) so auditors spend their engagement finding real vulnerabilities.

The repo has two distinct parts:
1. **Human-readable guides and checklists** for EVM, Solana, and Starknet protocols
2. **`audit-prep-skills/`** — Claude Code skills that automate the readiness checks described in the guides

---

## Project Structure

```
guides/
├── CLAUDE.md                          # This file
├── README.md                          # Main entry point: project overview, audit process, chain selector
├── CHECKLIST.md                       # General pre-audit checklist (chain-agnostic)
├── LICENSE                            # MIT
│
├── evm/                               # EVM (Solidity) chain guide
│   ├── README.md                      # Code quality, patterns, MEV/oracle/upgrade docs, testing requirements
│   ├── CHECKLIST.md                   # EVM-specific pre-audit checklist
│   └── examples/
│       ├── natspec-template.sol       # Full NatSpec documentation template
│       └── code-patterns.sol          # CEI, ReentrancyGuard, Pausable, pull-over-push patterns
│
├── solana/                            # Solana (Rust/Anchor) chain guide
│   ├── README.md                      # Naming, account structure, CPI risks, upgrade authority, testing
│   ├── CHECKLIST.md                   # Solana-specific pre-audit checklist
│   └── examples/
│       └── account-structure.rs      # UserVault PDA example with full account documentation
│
├── starknet/                          # Starknet (Cairo) chain guide
│   ├── README.md                      # Cairo edition, felt252 hazards, L1-L2 messaging, testing
│   ├── CHECKLIST.md                   # Starknet-specific pre-audit checklist
│   └── examples/
│       ├── cairo-patterns.cairo       # ReentrancyGuard, Pausable, CEI pattern in Cairo
│       └── doc-template.cairo         # Documentation comment template
│
├── assets/
│   └── README.md                      # Placeholder for logo.png
│
└── audit-prep-skills/                 # Claude Code skill library
    ├── CLAUDE.md                      # Rules for contributing to the skills subdirectory
    ├── README.md                      # Installation, usage, options, disclaimer
    ├── LICENSE                        # MIT
    └── audit-prep/                    # The audit-prep skill
        ├── SKILL.md                   # Orchestrator: 4-turn pipeline, report format, auto-fix, scan menu
        ├── VERSION                    # Skill version string
        ├── references/
        │   ├── shared-rules.md        # Rules shared across all agents (output format, scoring)
        │   └── agents/
        │       ├── testing-agent.md       # Agent A: Phases 1+2 (coverage, quality)
        │       ├── source-analysis-agent.md  # Agent B: Phases 3+4+6 (docs, hygiene, best practices)
        │       └── infrastructure-agent.md   # Agent C: Phases 5+7+8 (deps, deployment, project docs)
        └── evals/
            ├── evals.json             # Evaluation test cases
            └── grade.sh               # Grading script
```

---

## Guide Content Summary

### General (`CHECKLIST.md`, `README.md`)
- Applies to any protocol regardless of chain
- Covers: code readiness, documentation (SECURITY.md, KNOWN_ISSUES.md, scope.md), testing minimums, pre-engagement steps
- Links to chain-specific guides and the `audit-prep` skill

### EVM / Solidity (`evm/`)
- Locked pragmas, Solidity naming conventions, NatSpec on all public/external functions
- Battle-tested patterns: CEI, ReentrancyGuard, Pausable, pull-over-push, `Ownable2Step`
- EVM-specific risks to document: MEV surfaces, oracle staleness (Chainlink `latestRoundData` validation), upgrade proxy patterns, cross-chain differences
- Coverage minimums: line 95%, branch 90%, function 100%
- Test categories: unit, integration, fork, fuzz+invariant
- Tools: Foundry (primary), Hardhat, OpenZeppelin, Solmate/Solady

### Solana / Rust+Anchor (`solana/`)
- Pinned toolchain via `rust-toolchain.toml`, naming conventions, doc comments on all instructions
- Account structure documentation: PDA seeds, lifecycle, size calculation
- Solana-specific vulnerability classes: arbitrary CPI, missing ownership checks, reinitialization, duplicate mutable accounts, unchecked arithmetic, upgrade authority
- Coverage minimums: line 90%, branch 85%, critical instructions 100%
- Test categories: E2E flows, access control, edge cases, negative tests, fuzz (Trident)
- Tools: Anchor, Trident, Bankrun, Mollusk

### Starknet / Cairo (`starknet/`)
- Pinned Cairo edition in `Scarb.toml`, naming conventions, doc comments on interfaces
- Cairo-specific hazards: `felt252` vs typed integers for amounts, zero address validation, L1-L2 message replay protection, sequencer timestamp assumptions
- Upgradeability: document policy (upgradeable with multisig/timelock, or immutable)
- Coverage minimums: line 95%, branch 90%, function 100%
- Test categories: unit, integration, fork (Starknet Foundry), fuzz
- Tools: Scarb, Starknet Foundry (`snforge`), OpenZeppelin Cairo, Alexandria

---

## audit-prep Skill

The `audit-prep` skill is a 4-turn Claude Code pipeline for Solidity/EVM projects:

| Turn | What Happens |
|------|-------------|
| 0 | Print banner, ask which chain (EVM or Solana) |
| 1 | Ask for project location, discover files, detect framework, build agent bundles |
| 2 | Spawn 3 parallel agents (EVM) or 4 parallel agents (Solana) |
| 3 | Parse agent output, compute weighted score, render Audit Readiness Report |
| 4 | Optional: scan menu (chain-specific tools) |

**Phase weights — EVM (8 phases) and Solana (10 phases):**

| Phase | EVM weight | Solana weight |
|-------|-----------|---------------|
| 1. Test Coverage | 15% | 12% |
| 2. Test Quality | 15% | 12% |
| 3. Documentation | 10% | 8% |
| 4. Code Hygiene | 10% | 8% |
| 5. Dependencies | 10% | 8% |
| 6. Best Practices | 15% | 12% |
| 7. Deployment | 10% | 8% |
| 8. Project Docs | 15% | 12% |
| 9. Account Validation (Solana only) | — | 10% |
| 10. CPI Safety (Solana only) | — | 10% |

**Score verdicts:** 90–100 Audit Ready | 75–89 Almost Ready | 50–74 Needs Work | <50 Not Ready

**CLI options:** `--fix`, `--report <path>`, `--no-scan`, `--scanner <tool>`, `--diff <ref>`, `--ci --min-score N`, single phase by name

---

## Use Cases

### 1. Protocol team preparing for an audit
Run `/audit-prep` against the Solidity project to get a scored readiness report before booking the engagement. The report surfaces missing NatSpec, thin test coverage, floating pragmas, and missing SECURITY.md so the team can fix them before paying auditor rates.

### 2. Auditor onboarding reference
Share the chain-specific README (e.g., `evm/README.md`) with the development team at kickoff to align expectations: what documentation should exist, what test categories are required, what patterns to use.

### 3. Using a checklist to track preparation
Copy `CHECKLIST.md` (general) and the relevant chain checklist into a GitHub Issue or PR to track each item as the team completes it before the audit start date.

### 4. Auto-fixing common issues before audit
Run `/audit-prep --fix` to automatically insert NatSpec stubs, remove `console.log` imports, lock floating pragmas, and generate skeleton `SECURITY.md`, `scope.md`, and `KNOWN_ISSUES.md` files.

### 5. CI integration
Run `/audit-prep --ci --min-score 75` in CI pipelines to gate merges on audit readiness score. Outputs JSON and exits non-zero if score falls below the threshold.

### 6. Scoped diff check
Run `/audit-prep --diff main` to assess only files changed since the `main` branch — useful when preparing a specific feature branch for a focused review without re-scanning the entire codebase.

### 7. Static analysis
After the readiness report, use the scan menu to run Slither, Aderyn, or Pashov Solidity Auditor for automated vulnerability scanning. These findings are separate from the readiness score.

---

## Rules

- After each change, update all relevant READMEs. If a change affects a guide, checklist, skill behavior, or project structure, reflect it in the top-level `README.md`, the chain-specific `README.md`, and/or `audit-prep-skills/README.md` as appropriate. Never leave READMEs out of sync with the actual content.
- Do not add gas optimization checks; this repo is about audit preparation, not performance.
- Do not perform vulnerability analysis in the skills; agents must not do security assessments.
- Do not commit secrets, API keys, or personal data.
- Keep `SKILL.md` under 500 lines; move agent-specific logic to `references/agents/`.
- Every FAIL finding in a skill report must include a specific, actionable fix.
- Test skill changes against both Hardhat and Foundry projects before committing.
- The `audit-prep` skill is EVM/Solidity only; the guides cover EVM, Solana, and Starknet.
- Do not commit `.claude/` directory contents to this repo (keep superpowers workflow files on local branch only).
