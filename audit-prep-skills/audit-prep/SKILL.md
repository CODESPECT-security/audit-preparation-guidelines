---
name: audit-prep
description: >
  CODESPECT: Prepare smart contracts for a security audit. Supports EVM (Solidity) and Solana (Rust/Anchor).
  Covers test coverage, test quality, documentation, code hygiene, dependency health, best-practice
  enforcement, deployment readiness, and project documentation. Generates a scored Audit Readiness Report.
  Trigger on: "prepare for audit", "audit readiness", "pre-audit check", "audit prep", "NatSpec check",
  or any request to review a smart contract codebase before a security review.
---

# CODESPECT: Audit Preparation — Chain Dispatcher

## Turn 0: Banner, Version, and Chain Selection

Read in parallel:
- **Read:** `VERSION` file from this skill's base directory
- **Glob:** `**/references/chains/evm/agents/testing-agent.md` (confirms skill is installed correctly)

Print the banner below as plain text (not inside a code block). Apply ANSI color `\033[38;5;117m` (light sky blue) to the entire CODESPECT banner, `\033[38;5;153m` (pale blue) for the subtitle, and `\033[0m` to reset.

Then ask which chain:

```json
{
  "question": "Which chain is your project built on?",
  "header": "Chain",
  "multiSelect": false,
  "options": [
    {
      "label": "EVM (Solidity)",
      "description": "Ethereum, Base, Arbitrum, Optimism, and other EVM-compatible chains"
    },
    {
      "label": "Solana (Rust/Anchor)",
      "description": "Solana programs using the Anchor framework or native Rust"
    }
  ]
}
```

Map selection to chain key:
- "EVM (Solidity)" → `evm`
- "Solana (Rust/Anchor)" → `solana`

**Read** `references/chains/<chain>/orchestrator.md` and execute it. All CLI flags (`--fix`, `--report`, `--no-scan`, `--scanner`, `--diff`, `--ci`, `--min-score`) are forwarded.

## Banner

Before doing anything else, print the banner below as plain text (not inside a code block). Apply ANSI color `\033[38;5;117m` (light sky blue) to the entire CODESPECT banner, `\033[38;5;153m` (pale blue) for the subtitle, and `\033[0m` to reset at the end.

### Terminal

```
 ██████╗ ██████╗ ██████╗ ███████╗███████╗██████╗ ███████╗ ██████╗████████╗
██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝
██║     ██║   ██║██║  ██║█████╗  ███████╗██████╔╝█████╗  ██║        ██║   
██║     ██║   ██║██║  ██║██╔══╝  ╚════██║██╔═══╝ ██╔══╝  ██║        ██║   
╚██████╗╚██████╔╝██████╔╝███████╗███████║██║     ███████╗╚██████╗   ██║   
 ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚═╝     ╚══════╝ ╚═════╝   ╚═╝   

Audit Preparation v3.0
```

### For `--report` markdown files

Use the same layout inside a code block (no ANSI codes):

```
 ██████╗ ██████╗ ██████╗ ███████╗███████╗██████╗ ███████╗ ██████╗████████╗
██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝
██║     ██║   ██║██║  ██║█████╗  ███████╗██████╔╝█████╗  ██║        ██║   
██║     ██║   ██║██║  ██║██╔══╝  ╚════██║██╔═══╝ ██╔══╝  ██║        ██║   
╚██████╗╚██████╔╝██████╔╝███████╗███████║██║     ███████╗╚██████╗   ██║   
 ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚═╝     ╚══════╝ ╚═════╝   ╚═╝   

Audit Preparation v3.0
```
