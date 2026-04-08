# CLAUDE.md

Instructions for Claude when contributing to this repository.

## What This Repo Is

A library of Claude Code skills for smart contract security, built by CODESPECT. Each skill is a self-contained capability in its own directory.

## Structure

```
audit-ready/           # Multi-chain audit preparation pipeline
  SKILL.md            # Chain dispatcher (prints banner, asks chain, reads orchestrator)
  VERSION             # Skill version
  references/
    shared-rules.md   # Output format and DO NOT rules (shared across all chains)
    chains/
      evm/
        orchestrator.md         # EVM pipeline (Turns 0-4)
        agents/
          testing-agent.md      # Phases 1+2 (coverage, quality)
          source-analysis-agent.md  # Phases 3+4+6 (docs, hygiene, best practices)
          infrastructure-agent.md   # Phases 5+7+8 (deps, deployment, project docs)
      solana/
        orchestrator.md         # Solana pipeline (Turns 0-4)
        agents/
          testing-agent.md      # Phases 1+2 (Solana)
          source-analysis-agent.md  # Phases 3+4+6 (Solana)
          infrastructure-agent.md   # Phases 5+7+8 (Solana)
          account-validation-agent.md  # Phases 9+10 (Solana-specific)
  evals/
    evm/              # EVM eval test cases and grading script
    solana/           # Solana eval test cases and grading script
```

## Rules

- One skill, one purpose.
- Keep SKILL.md under 500 lines; use references/ for agent-specific instructions.
- No gas optimization checks (out of scope for audit preparation).
- No vulnerability analysis; agents must not perform security assessments.
- Every FAIL finding must include a specific, actionable fix.
- Do not commit secrets, API keys, or personal data.
- Test changes against both eval projects (Hardhat + Foundry) before submitting.
