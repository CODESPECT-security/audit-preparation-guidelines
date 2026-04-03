# CODESPECT — Claude Code Skills

A collection of open-source [Claude Code](https://claude.ai/claude-code) skills built by [CODESPECT](https://codespect.net) to help development teams ship safer smart contracts.

These skills automate the tedious parts of security preparation so teams can focus on building — and auditors can focus on finding real bugs instead of chasing missing documentation and untested code.

## Why

Too much audit time gets wasted on preventable issues: missing tests, undocumented functions, floating pragmas, uninitialized submodules. Every hour an auditor spends on hygiene issues is an hour not spent hunting critical vulnerabilities.

These skills exist to close that gap. Run them before your audit engagement and arrive fully prepared — better coverage, cleaner code, fewer back-and-forth cycles, and a more thorough security review.

## Skills

### audit-prep

**Prepare a Solidity project for a security audit.**

Runs an 8-phase automated readiness check across your entire codebase and produces a scored report with actionable findings:

| Phase | What it checks |
|-------|---------------|
| 1. Test Coverage | Branch/line coverage, untested contracts, compiler warnings |
| 2. Test Quality | Assertion density, edge cases, negative tests, integration and fork tests |
| 3. Documentation | NatSpec coverage, stale @param tags, missing @return, custom error @notice |
| 4. Code Hygiene | TODOs, console imports, floating pragmas, unused imports, error consistency, `tx.origin` auth, unjustified `unchecked` blocks |
| 5. Dependencies | Outdated packages, CVEs, uninitialized submodules, patched deps |
| 6. Best Practices | SafeERC20, CEI pattern, reentrancy guards, access control, upgradeable patterns |
| 7. Deployment | Build/test pass, deploy scripts, verification setup, .env.example |
| 8. Project Docs | Architecture overview, trust assumptions, invariants, known issues, scope definition, MEV/oracle/upgrade docs (context-sensitive) |

**Features:**
- Parallel agent architecture — 3 agents run simultaneously for fast results
- Grep-based source analysis — no full source code in context, minimal token usage
- Every finding includes a specific fix action
- Supports Foundry and Hardhat projects
- Optional static analysis menu (Slither, Aderyn, Mythril)
- Auto-fix mode for common issues (NatSpec stubs, pragma locking, console removal)
- CI mode with JSON output and configurable score threshold

## Disclaimer

This tool is **not a bug hunter**. It does not find vulnerabilities, detect complex bugs, or perform any form of security analysis. It is **not a substitute for a security audit**.

audit-prep is a simple preparation tool — it checks that your project's tests, documentation, code hygiene, and infrastructure are in order *before* an audit begins, so auditors can spend their time on what matters: finding real bugs.

## Prerequisites

- [Claude Code](https://claude.ai/claude-code) installed and authenticated

## Install

1. Clone the repo and symlink the skill into your Claude Code skills directory:

```bash
git clone https://github.com/CDSecurity/cdsecurity-skills.git ~/cdsecurity-skills
ln -s ~/cdsecurity-skills/audit-prep ~/.claude/skills/audit-prep
```

2. Verify — you should see `SKILL.md`:

```bash
ls ~/.claude/skills/audit-prep/SKILL.md
```

To update later:

```bash
cd ~/cdsecurity-skills && git pull
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

Found a bug? Have an idea for a new check? PRs and issues are welcome.

If you build a skill that helps make smart contracts safer, we'd love to include it.

## License

[MIT](LICENSE) © CODESPECT

## About CODESPECT

[CODESPECT](https://codespect.net) is a smart contract security firm focused on EVM and Solana protocols. We perform manual security audits, build security tooling, and contribute to making the ecosystem safer for everyone.

## Acknowledgments

The original audit-prep skill was created by [CD Security](https://cdsecurity.io). This version has been adopted, rebranded, and extended by CODESPECT with additional checks and chain-specific enhancements.
