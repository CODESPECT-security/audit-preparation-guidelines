<!-- TODO: replace with actual logo asset once available -->
<img src="./assets/logo.png" alt="CODESPECT" width="300" />

# CODESPECT — Smart Contract Audit Preparation Guides

**Billions lost to hacks. Millions more wasted on audits.**

The DeFi ecosystem has bled billions to exploits that thorough audits could have caught. But protocols also routinely waste audit budget on something different: paying senior security researchers day rates to read documentation, reverse-engineer architectures, and decode undocumented logic — work that should have been done before the audit started.

> Auditors should spend their time finding vulnerabilities, not understanding your protocol.

This guide helps you prepare. Properly prepared protocols spend significantly less time on auditor orientation and significantly more time on what matters — finding and fixing security issues before deployment.

---

## Key Principles

- **Preparation reduces cost** — Well-prepared protocols need fewer audit days. Poorly prepared ones pay for orientation.
- **Docs and tests matter as much as code** — An auditor who understands your intent finds more bugs in less time.
- **Auditors find bugs, not architecture** — If your auditor is asking "what does this contract do?", you are burning budget.
- **No audit is a security guarantee** — Audits significantly reduce risk. They do not eliminate it. Plan accordingly.

---

## What Is a Smart Contract Audit?

A professional audit is a comprehensive manual review of your code, architecture, and security model by experienced security researchers. The goal is to surface:

- Logic errors and edge cases your team missed
- Economic model vulnerabilities (tokenomics, incentive misalignments)
- Access control weaknesses and privilege escalation paths
- Protocol-specific attack vectors: MEV, flash loans, oracle manipulation, CPI abuse

Automated scanners catch the easy stuff. Experienced auditors catch the rest.

For chain-specific preparation details, jump to the [EVM Guide](./evm/README.md) or the [Solana Guide](./solana/README.md).

---

## Audit Process

| Phase | Duration | What Happens |
|---|---|---|
| Pre-Assessment | 1–2 days | Code readiness check, scope confirmation, blocker identification |
| Planning | 1–2 days | Priority alignment, critical component identification, communication setup |
| Auditing | Project-dependent | In-depth manual review, dynamic analysis, custom test scenarios |
| Reporting | 2–3 days | Findings report with severity classifications and remediation guidance |
| Fix Verification | 1–2 days | Verify implemented fixes, re-test affected areas |
| Final Report | 1 day | Complete signed report, production readiness assessment |

---

## Choosing an Audit Firm

Not all audit firms are equivalent. Before signing:

1. **Who are the actual auditors assigned to your project?** Not the sales team — the researchers who will read your code. Check their public track record.
2. **What percentage of your budget goes to auditors vs. firm overhead?**
3. **What is their specific experience with your stack?** EVM and Solana have meaningfully different vulnerability profiles.
4. **Do they rely primarily on automated tools or manual review?** Automated tools are a starting point. They are not a substitute for expertise.
5. **Can they provide references from similar protocols?**

> Avoid firms that lead with tool-generated reports. Scanners miss the bugs that drain protocols.

---

## Choose Your Chain

| | Guide | Checklist |
|---|---|---|
| **EVM (Solidity)** | [→ EVM Audit Preparation Guide](./evm/README.md) | [→ EVM Checklist](./evm/CHECKLIST.md) |
| **Solana (Rust/Anchor)** | [→ Solana Audit Preparation Guide](./solana/README.md) | [→ Solana Checklist](./solana/CHECKLIST.md) |

Not sure where to start? Use the [General Pre-Audit Checklist](./CHECKLIST.md) — it applies to any protocol regardless of chain.

---

## Work With CODESPECT

**CODESPECT** provides deep-expertise security audits for EVM and Solana protocols. Our auditors are protocol specialists, not generalists running tools.

- **Website:** [codespect.net](https://codespect.net)
- **Email:** [audits@codespect.xyz](mailto:audits@codespect.xyz)
- **GitHub:** [github.com/CODESPECT-security](https://github.com/CODESPECT-security)
