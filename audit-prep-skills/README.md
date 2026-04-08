# CODESPECT: Claude Code Skills

Open-source [Claude Code](https://claude.ai/claude-code) skills by [CODESPECT](https://codespect.net) that help development teams ship safer smart contracts.

These skills handle the repetitive parts of security preparation — so teams can focus on building, and auditors can focus on finding real vulnerabilities.

## Why

Audit time is expensive. Too much of it gets burned on avoidable issues: missing tests, undocumented functions, floating pragmas, uninitialized submodules. Every hour spent on hygiene is an hour not spent finding critical bugs.

These skills exist to fix that. Run them before your engagement and show up prepared: stronger coverage, cleaner code, fewer review cycles, and a more effective audit.

## Skills

### audit-prep

**Get your smart contract project audit-ready — EVM and Solana.**

Runs an automated readiness check across your codebase and produces a scored report with actionable findings.

#### EVM (Solidity) — 8 phases

| Phase | Checks |
|-------|--------|
| 1. Test Coverage | forge/hardhat coverage, compiler warnings |
| 2. Test Quality | Assertion density, fuzz tests, fork tests |
| 3. Documentation | NatSpec on all public/external functions |
| 4. Code Hygiene | TODOs, floating pragma, console imports |
| 5. Dependencies | npm/git submodule CVEs |
| 6. Best Practices | SafeERC20, CEI pattern, reentrancy guards |
| 7. Deployment | forge build, deploy scripts |
| 8. Project Docs | Architecture, trust assumptions, scope |

#### Solana (Rust/Anchor) — 10 phases

| Phase | Checks |
|-------|--------|
| 1. Test Coverage | cargo llvm-cov coverage, anchor build warnings |
| 2. Test Quality | Assertion density, access control tests, Trident fuzz |
| 3. Documentation | Rust `///` doc comments, `# Access Control` / `# Errors` sections |
| 4. Code Hygiene | TODOs, direct arithmetic, `init_if_needed`, `msg!` debug logs |
| 5. Dependencies | cargo audit, Cargo.lock, rust-toolchain.toml |
| 6. Best Practices | Raw AccountInfo, bump storage, signer validation, events |
| 7. Deployment | anchor build, deploy scripts, upgrade authority disposition |
| 8. Project Docs | Architecture, trust assumptions, scope, upgrade authority (required) |
| 9. Account Validation | PDA docs, bump on-chain, `init_if_needed` guard, duplicate mutable accounts |
| 10. CPI Safety | Arbitrary CPI, program ID validation, `.reload()` after CPI |

**Features:**
- Parallel agent architecture: 3 agents (EVM) or 4 agents (Solana) run simultaneously
- Grep-based source analysis: no full source code in context, minimal token usage
- Every finding includes a specific, actionable fix
- Supports Foundry and Hardhat (EVM) and Anchor (Solana)
- Optional static analysis menu: Slither, Aderyn, Pashov (EVM) or Trident, Soteria (Solana)
- Auto-fix mode for common issues (NatSpec stubs, pragma locking, console removal) — EVM only
- CI mode with JSON output and configurable score threshold

## Disclaimer

This tool is **not a vulnerability scanner**. It does not detect bugs, analyze attack surfaces, or replace a security audit in any way.

audit-prep is a preparation tool. It verifies that your tests, documentation, code hygiene, and infrastructure meet a baseline before an audit starts — so auditors can spend their time on what actually matters.

## Prerequisites

- [Claude Code](https://claude.ai/claude-code) installed and authenticated

## Install

1. Clone the repo and symlink the skill into your Claude Code skills directory:

```bash
git clone https://github.com/CODESPECT-security/audit-preparation-guidelines.git ~/audit-preparation-guidelines
ln -s ~/audit-preparation-guidelines/audit-prep ~/.claude/skills/audit-prep
```

2. Verify you should see `SKILL.md`:

```bash
ls ~/.claude/skills/audit-prep/SKILL.md
```

To update later:

```bash
cd ~/audit-preparation-guidelines && git pull
```

## Run

1. Navigate to a Solidity project and start Claude Code:

```bash
cd /path/to/your/project
claude
```

2. Run the full audit-prep pipeline:

```
/audit-prep
```

Claude will ask which chain (EVM or Solana), then which project to analyze.

Or use natural language:

```
prepare this project for audit
```

### Options

Run a single phase only:

```
/audit-prep coverage
```

```
/audit-prep docs
```

```
/audit-prep hygiene
```

Available phases: `coverage`, `quality`, `docs`, `hygiene`, `deps`, `practices`, `deploy`, `context`

Auto-fix common issues (NatSpec stubs, console removal, pragma locking, SafeERC20 wrapping):

```
/audit-prep --fix
```

Save the report to a file:

```
/audit-prep --report audit-prep-report.md
```

Run static analysis only:

```
/audit-prep scan
```

Skip the static analysis prompt:

```
/audit-prep --no-scan
```

CI mode (JSON output, exits with score check):

```
/audit-prep --ci --min-score 75
```

Scope to recent changes only:

```
/audit-prep --diff main
```

## Contributing

Found a bug or have an idea for a new check? PRs and issues are welcome.

If you build a skill that makes smart contracts safer, we'd love to include it.

## License

[MIT](LICENSE) © CODESPECT

## About CODESPECT

[CODESPECT](https://codespect.net) is a smart contract security firm covering EVM, Solana, and Starknet protocols. We do manual security audits, build security tooling, and work to make the ecosystem safer for everyone.

## Acknowledgments

Inspired by an early proof-of-concept from [CD Security](https://cdsecurity.io). CODESPECT has since rebuilt the pipeline from the ground up with a new architecture, expanded checks, and chain-specific enhancements.
