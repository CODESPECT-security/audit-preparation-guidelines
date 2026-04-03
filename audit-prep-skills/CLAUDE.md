# CLAUDE.md

Instructions for Claude when contributing to this repository.

## What This Repo Is

A library of Claude Code skills for smart contract security, built by CODESPECT. Each skill is a self-contained capability in its own directory.

## Structure

```
audit-prep/          # Solidity audit preparation pipeline
  SKILL.md           # Main orchestrator
  VERSION            # Skill version
  references/        # Agent instructions and shared rules
  evals/             # Test cases and grading scripts
```

## Rules

- One skill, one purpose.
- Keep SKILL.md under 500 lines — use references/ for agent-specific instructions.
- No gas optimization checks — out of scope for audit preparation.
- No vulnerability analysis — agents must not perform security assessments.
- Every FAIL finding must include a specific, actionable fix.
- Do not commit secrets, API keys, or personal data.
- Test changes against both eval projects (Hardhat + Foundry) before submitting.
