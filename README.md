# CODESPECT: Smart Contract Audit Preparation Guides

**Billions lost to hacks. Millions more wasted on audits.**

The DeFi ecosystem has bled billions to exploits that thorough audits could have caught. But protocols also routinely waste audit budget on something different: paying senior security researchers day rates to read documentation, reverse-engineer architectures, and decode undocumented logic; this is work that should have been done before the audit started.

> Auditors should spend their time finding vulnerabilities, not understanding your protocol.

This guide helps you prepare. Properly prepared protocols spend significantly less time on auditor orientation and significantly more time on what matters: finding and fixing security issues before deployment.

---

## Key Principles

- **Preparation reduces cost.** Well-prepared protocols need fewer audit days. Poorly prepared ones pay for orientation.
- **Docs and tests matter as much as code.** An auditor who understands your intent finds more bugs in less time.
- **Auditors find bugs, not architecture.** If your auditor is asking "what does this contract do?", you are burning budget.
- **No audit is a security guarantee.** Audits significantly reduce risk. They do not eliminate it. Plan accordingly.

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

| Phase | What Happens |
|---|---|
| Kickoff | Scope confirmation, documentation handoff, initial Q&A with the development team |
| Audit | In-depth manual review, static analysis, custom test scenarios |
| Report Drafting | Findings documented with severity classifications, proof-of-concept, and remediation guidance |
| Remediation | Development team implements fixes and provides a response to each finding |
| Fix Review | Each fix independently verified, regressions checked, affected areas re-tested |
| Final Report | Complete signed report delivered, production readiness confirmed |

---

## Choosing an Audit Firm

Not all audit firms are equivalent. Before signing:

1. **Who are the actual auditors assigned to your project?** Not the sales team. Check the researchers who will read your code and verify their public track record.
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
| **Starknet (Cairo)** | [→ Starknet Audit Preparation Guide](./starknet/README.md) | [→ Starknet Checklist](./starknet/CHECKLIST.md) |

Not sure where to start? Use the [General Pre-Audit Checklist](./CHECKLIST.md); it applies to any protocol regardless of chain.

---

## Automated Assessment

Once your code is ready, use the **audit-prep** skill to run an automated readiness check against your Solidity project. It scores your project across 8 phases — test coverage, test quality, documentation, code hygiene, dependencies, best practices, deployment readiness, and project documentation — and produces a ranked report with specific fixes.

```
/audit-prep
```

The skill is available in the [`audit-prep-skills/`](./audit-prep-skills/README.md) directory. It does not find vulnerabilities; it checks that everything auditors expect to see is in place before the engagement begins.

---

## Work With CODESPECT

**CODESPECT** provides deep-expertise security audits for EVM and Solana protocols. Our auditors are protocol specialists, not generalists running tools.

- **Website:** [codespect.net](https://codespect.net)
- **Email:** [audits@codespect.xyz](mailto:audits@codespect.xyz)
- **GitHub:** [github.com/CODESPECT-security](https://github.com/CODESPECT-security)
