# Multi-Chain audit-prep Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure `audit-prep-skills/audit-prep/` into a chain-aware skill with a thin dispatcher, per-chain orchestrators, and a new Solana pipeline covering 10 audit-readiness phases.

**Architecture:** `SKILL.md` becomes a ~60-line dispatcher that prints the banner and asks which chain, then reads and executes `references/chains/<chain>/orchestrator.md`. EVM content is moved to `references/chains/evm/`; Solana content is new under `references/chains/solana/`. `references/shared-rules.md` is unchanged.

**Tech Stack:** Claude Code skill markdown files; Bash (anchor, cargo, cargo-llvm-cov, cargo audit) for Solana checks; existing Foundry/Hardhat commands for EVM unchanged.

---

## File Map

### Modified
- `audit-prep-skills/audit-prep/SKILL.md` — rewritten as dispatcher (~60 lines)
- `audit-prep-skills/CLAUDE.md` — update structure docs
- `audit-prep-skills/README.md` — add Solana to skill description

### Moved (content unchanged)
- `references/agents/testing-agent.md` → `references/chains/evm/agents/testing-agent.md`
- `references/agents/source-analysis-agent.md` → `references/chains/evm/agents/source-analysis-agent.md`
- `references/agents/infrastructure-agent.md` → `references/chains/evm/agents/infrastructure-agent.md`
- `evals/evals.json` → `evals/evm/evals.json`
- `evals/grade.sh` → `evals/evm/grade.sh`

### Created
- `references/chains/evm/orchestrator.md` — current SKILL.md pipeline logic, paths updated
- `references/chains/solana/orchestrator.md` — new Solana pipeline
- `references/chains/solana/agents/testing-agent.md` — Phases 1+2 (Solana)
- `references/chains/solana/agents/source-analysis-agent.md` — Phases 3+4+6 (Solana)
- `references/chains/solana/agents/infrastructure-agent.md` — Phases 5+7+8 (Solana)
- `references/chains/solana/agents/account-validation-agent.md` — Phases 9+10 (Solana-only)
- `evals/solana/evals.json`
- `evals/solana/grade.sh`

All paths below are relative to `audit-prep-skills/audit-prep/`.

---

## Task 1: Scaffold New Directory Structure

**Files:** directories only

- [ ] **Step 1: Create chain directories**

```bash
cd /home/talfao/Dev/guides/audit-prep-skills/audit-prep
mkdir -p references/chains/evm/agents
mkdir -p references/chains/solana/agents
mkdir -p evals/evm
mkdir -p evals/solana
```

- [ ] **Step 2: Verify structure**

```bash
find references/chains evals -type d | sort
```

Expected output:
```
evals/evm
evals/solana
references/chains
references/chains/evm
references/chains/evm/agents
references/chains/solana
references/chains/solana/agents
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "chore(audit-prep): scaffold multi-chain directory structure"
```

---

## Task 2: Move EVM Agents and Evals

**Files:** move only — no content changes

- [ ] **Step 1: Move agent files**

```bash
cd /home/talfao/Dev/guides/audit-prep-skills/audit-prep
git mv references/agents/testing-agent.md references/chains/evm/agents/testing-agent.md
git mv references/agents/source-analysis-agent.md references/chains/evm/agents/source-analysis-agent.md
git mv references/agents/infrastructure-agent.md references/chains/evm/agents/infrastructure-agent.md
```

- [ ] **Step 2: Move evals**

```bash
git mv evals/evals.json evals/evm/evals.json
git mv evals/grade.sh evals/evm/grade.sh
```

- [ ] **Step 3: Remove now-empty agents directory**

```bash
rmdir references/agents
```

- [ ] **Step 4: Verify files exist at new paths**

```bash
ls references/chains/evm/agents/
ls evals/evm/
```

Expected:
```
infrastructure-agent.md  source-analysis-agent.md  testing-agent.md
evals.json  grade.sh
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor(audit-prep): move EVM agents and evals to chains/evm/"
```

---

## Task 3: Create EVM Orchestrator

**Files:**
- Create: `references/chains/evm/orchestrator.md`

This is the current `SKILL.md` pipeline logic (Turns 0–4 + Auto-Fix) moved here. Three changes from current `SKILL.md`:
1. No frontmatter (that stays in `SKILL.md`)
2. Banner is already printed by dispatcher — Turn 0 skips banner printing and just does path discovery + project selection
3. Path variables: `{ref_path}` → `{chain_agents_path}` and `{shared_rules}`

- [ ] **Step 1: Write the EVM orchestrator**

Create `references/chains/evm/orchestrator.md` with this content:

```markdown
# EVM (Solidity) Audit Preparation — Orchestrator

Orchestrate the EVM audit-prep pipeline for Solidity projects (Foundry or Hardhat).
Do NOT perform analysis; discover files, dispatch agents, compile the scored report.

## Modes

- **Default:** full pipeline, all 8 phases + static analysis offer.
- **Single phase:** `coverage` | `quality` | `docs` | `hygiene` | `deps` | `practices` | `deploy` | `context`
- **`scan`:** static analysis only.
- **`--fix`:** auto-apply fixes (NatSpec stubs, console removal, pragma locking, SafeERC20 wrapping).
- **`--report <path>`:** write markdown report to file (no ANSI codes).
- **`--no-scan`:** skip static analysis offer.
- **`--scanner <tool>`:** run specific tool without prompting.
- **`--diff <ref>`:** scope to files changed since git ref.
- **`--ci`:** JSON output. Exit 0 if score >= threshold (default 75, `--min-score N`).

## Report Format

Clean markdown. Each phase = one table with Status, Finding, and Recommendation columns.
Score summary at the end. When rendered via `--report`, produces a polished `.md` file.

The report has these sections in order:
1. Header (project, framework, scope)
2. Phase 1–8, each as a titled section with a results table
3. Score summary table
4. Quick Wins table

### Banner

For `--report` markdown files, include the banner from the parent `SKILL.md` as an uncolored code block at the top of the file. Do NOT re-print it in the terminal (the dispatcher already printed it).

### Phase section template

```markdown
## 1. Test Coverage

| Status | Finding | Recommendation |
|--------|---------|----------------|
| FAIL | Compiler warning: unused param in ConfigProvider:288 | Remove or rename the unused parameter |
| PASS | 4/4 contracts have test files | - |
| PASS | Branch coverage: 95.93% | - |
```

- **Status**: `PASS` or `FAIL`
- **Finding**: concise description of what was checked and the result
- **Recommendation**: specific action to fix (only for FAIL rows; use `-` for PASS)

### Score summary

```markdown
## Score Summary

| Phase | Score |
|-------|-------|
| 1. Test Coverage | 87/100 |
| 2. Test Quality | 85/100 |
| ... | ... |
| **Overall** | **82/100: Almost Ready** |
```

### Quick Wins

```markdown
## Quick Wins

| # | Action | Location |
|---|--------|----------|
| 1 | Create deployment scripts | scripts/deploy.ts |
| 2 | Create SECURITY.md with trust assumptions | project root |
| 3 | Add more assertions to thin tests | test/ |
```

No deduction numbers, no weights, no `[-N]` annotations.

## Execution

### Turn 0: Path Discovery and Project Selection

Read the skill's paths in parallel:
- **Glob:** `**/references/chains/evm/agents/testing-agent.md` → extract parent directory as `{chain_agents_path}`
- **Glob:** `**/references/shared-rules.md` → extract full path as `{shared_rules}`

Then ask the user where the project is:

```json
{
  "question": "Where is the project you want to prepare for audit?",
  "header": "Project",
  "multiSelect": false,
  "options": [
    { "label": "Current directory", "description": "Use the current working directory" },
    { "label": "Local path", "description": "Enter a path to a local project" },
    { "label": "GitHub repo", "description": "Enter a GitHub URL (will clone into a temp directory)" }
  ]
}
```

If **Current directory**: use the cwd as `{project_dir}`.
If **Local path**: user provides a path, use it as `{project_dir}`.
If **GitHub repo**: clone with `git clone <url> /tmp/audit-prep-<repo-name>` and use that as `{project_dir}`.

### Turn 1: Discover and Prepare

Make these **parallel tool calls** in ONE message:
a. **Bash:** detect framework: check for `foundry.toml`, `hardhat.config.js`, `hardhat.config.ts`
b. **Bash:** find in-scope `.sol` files. Exclude `test/`, `script/`, `lib/`, `node_modules/`, `interfaces/`, `mocks/`. Check both `src/` and `contracts/`. If `--diff <ref>`, use `git diff --name-only <ref> -- '*.sol'`.
c. **Bash:** find test files: `find test/ -name '*.sol' -o -name '*.ts' -o -name '*.js'`
d. **Bash:** count total lines in scope: `wc -l` on discovered source files
e. **Bash:** `mkdir -p .audit-prep` → `{bundle_dir}` = `.audit-prep`
f. **ToolSearch:** `mcp__sc-auditor` (for scan menu in Turn 4)

Then create agent bundles in a **single Bash call**:

```bash
# File list (one per line)
printf '%s\n' <in-scope-files> > {bundle_dir}/files.txt

# Agent A: Testing (Phases 1+2)
{
  printf 'framework: %s\nproject_dir: %s\n\n' "<fw>" "<dir>"
  echo "# Test files:"
  for f in <test-files>; do
    printf '%s (%s lines)\n' "$f" "$(wc -l < "$f")"
  done
  echo ""
  echo "# In-scope source files:"
  cat {bundle_dir}/files.txt
  echo ""
  cat {chain_agents_path}/testing-agent.md
  echo ""
  cat {shared_rules}
} > {bundle_dir}/agent-a.md

# Agent B: Source Analysis (Phases 3+4+6)
{
  printf 'project_dir: %s\n\n' "<dir>"
  echo "# In-scope source files:"
  cat {bundle_dir}/files.txt
  echo ""
  cat {chain_agents_path}/source-analysis-agent.md
  echo ""
  cat {shared_rules}
} > {bundle_dir}/agent-b.md

# Agent C: Infrastructure (Phases 5+7+8)
{
  printf 'framework: %s\nproject_dir: %s\n\n' "<fw>" "<dir>"
  cat {chain_agents_path}/infrastructure-agent.md
  echo ""
  cat {shared_rules}
} > {bundle_dir}/agent-c.md

echo "=== Bundles ==="
wc -l {bundle_dir}/agent-*.md
```

Print: `<project> | EVM (Solidity) | <N> files, <M> lines`

### Turn 2: Spawn

**First**, create 3 tasks so the user sees progress spinners:

| Task | Subject | Active Form |
|------|---------|-------------|
| A | Test coverage & quality (Phases 1-2) | Analyzing test coverage & quality |
| B | Source code analysis (Phases 3, 4, 6) | Analyzing source code |
| C | Infrastructure checks (Phases 5, 7, 8) | Checking infrastructure |

Use TaskCreate for each, then immediately set all 3 to `in_progress` via TaskUpdate.

**Then**, in the SAME message, spawn **3 parallel Agent calls:**

**Agent A: Testing (Phases 1 + 2):**
```
Read your full bundle at {bundle_dir}/agent-a.md.
Execute Phases 1 and 2 exactly as specified.
Output ONLY the PHASE/FAIL/PASS structured format from the shared rules.
Do NOT skip any phase. Do NOT add commentary or tables.
```

**Agent B: Source Analysis (Phases 3 + 4 + 6):**
```
Read your full bundle at {bundle_dir}/agent-b.md.
Execute Phases 3, 4, and 6 exactly as specified.
Use Grep and Read to analyze the source files listed in the bundle.
Do NOT read all source files at once; use targeted queries per check.
Output ONLY the PHASE/FAIL/PASS structured format from the shared rules.
Do NOT skip any phase. Do NOT perform vulnerability analysis.
```

**Agent C: Infrastructure (Phases 5 + 7 + 8):**
```
Read your full bundle at {bundle_dir}/agent-c.md.
Execute Phases 5, 7, and 8 exactly as specified.
Output ONLY the PHASE/FAIL/PASS structured format from the shared rules.
Do NOT skip any phase. Do NOT add commentary or tables.
```

As each agent completes, mark its task as `completed` via TaskUpdate.

### Turn 3: Score and Report

**Parse** each agent's output. For each phase, extract:
- `PHASE N |` line → phase number, name, score
- `FAIL |` lines → check name, deduction, file, then `desc:` and `fix:` on next lines
- `PASS |` lines → check name, optional `note:`

**Validate:** For each expected phase (1–8):
- Missing `PHASE N` marker → score = 0, add note "(not reported by agent)"
- Missing `SCORE:` → compute as 100 minus sum of extracted deductions
- No FAIL/PASS lines → flag "(no details reported)"

**Compute weighted score:**

| Phase | Weight |
|-------|--------|
| 1. Coverage | 15% |
| 2. Quality | 15% |
| 3. Documentation | 10% |
| 4. Hygiene | 10% |
| 5. Dependencies | 10% |
| 6. Best Practices | 15% |
| 7. Deployment | 10% |
| 8. Project Docs | 15% |

**Verdict:** 90–100 Audit Ready | 75–89 Almost Ready | 50–74 Needs Work | <50 Not Ready
**Override:** If Phase 1 (Coverage) score < 90, verdict CANNOT be "Audit Ready"; cap at "Almost Ready" and append "(coverage below 90%)".

**Render the report as clean markdown** using the format from the Report Format section.

For each phase, build a table with Status | Finding | Recommendation columns.
FAIL rows get a specific recommendation. PASS rows get `-` in the recommendation column.
Group related PASS items into single rows where natural.

End with the Score Summary table and Quick Wins table.
**Quick Wins** = top 5 most impactful FAIL findings. Each shows the fix action and where to apply it.

If `--report <path>`: write the markdown to the specified file path (include banner as code block at top).
If `--ci`: JSON `{"score": N, "verdict": "...", "phases": [...], "findings": [...]}`.

### Turn 4: Scan Menu

Skip if `--no-scan`. If `--scanner <tool>`, run directly.

**Detection:**

```bash
echo "=== SCAN DETECTION ==="
which slither 2>/dev/null && echo "SLITHER=yes" || echo "SLITHER=no"
which aderyn 2>/dev/null && echo "ADERYN=yes" || echo "ADERYN=no"
which myth 2>/dev/null && echo "MYTHRIL=yes" || echo "MYTHRIL=no"
```

Also check ToolSearch results from Turn 1 for `mcp__sc-auditor__run-slither`, `mcp__sc-auditor__run-aderyn`.
Also check the available skills list for `solidity-auditor`.

**Present the scan menu using AskUserQuestion with multiSelect: true.**

Always include all four options. Set each tool's description dynamically based on availability.

```json
{
  "question": "Which scanners do you want to run?",
  "header": "Bug Scan",
  "multiSelect": true,
  "options": [
    { "label": "Slither", "description": "Static analysis for Solidity (available via MCP / installed locally / not installed)" },
    { "label": "Aderyn", "description": "Rust-based static analyzer (available via MCP / installed locally / not installed)" },
    { "label": "Pashov Solidity Auditor", "description": "AI-powered audit skill (available as skill / not installed)" },
    { "label": "Import custom scanner", "description": "Provide a CLI command to run your own scanner" }
  ]
}
```

**Tool execution reference:**

| Tool | Local CLI | MCP | Skill |
|------|-----------|-----|-------|
| Slither | `slither . --filter-paths "test\|script\|lib\|node_modules"` | `mcp__sc-auditor__run-slither` | - |
| Aderyn | `aderyn .` | `mcp__sc-auditor__run-aderyn` | - |
| Pashov Solidity Auditor | - | - | `solidity-auditor` skill |

Priority when multiple sources available: MCP > local CLI > skill.

Findings from scanners do NOT affect the audit-prep score.

## Auto-Fix (`--fix`)

### Code fixes (applied to source files)
| Fix | Action |
|-----|--------|
| NatSpec stubs | Insert @notice, @param, @return above undocumented functions |
| Console removal | Remove console.sol imports and console.log calls |
| Pragma locking | Replace `^0.8.x` with `0.8.x` |
| SafeERC20 wrapping | Add `using SafeERC20 for IERC20;`, replace direct calls |
| SPDX headers | Add `// SPDX-License-Identifier: MIT` to files missing it (prompt for license) |

### Template generation (creates new files if missing)
| File | Content |
|------|---------|
| `SECURITY.md` | Skeleton: Roles & Permissions, Trust Assumptions, Centralization Risks, Known Risks sections. Pre-fill role names from AccessControl/Ownable usage in source. |
| `scope.md` | Generate from discovered in-scope files: contract name, file path, line count, brief description from @title NatSpec |
| `KNOWN_ISSUES.md` | Skeleton: header + "Document any known limitations, accepted risks, or intentional design trade-offs here." |

Templates are only created if the file does not already exist.
```

- [ ] **Step 2: Verify file exists and is under 500 lines**

```bash
wc -l references/chains/evm/orchestrator.md
```

Expected: under 500 lines.

- [ ] **Step 3: Commit**

```bash
git add references/chains/evm/orchestrator.md
git commit -m "feat(audit-prep): add EVM orchestrator with updated chain-specific paths"
```

---

## Task 4: Rewrite SKILL.md as Dispatcher

**Files:**
- Modify: `SKILL.md`

- [ ] **Step 1: Rewrite SKILL.md**

Replace the entire content of `SKILL.md` with:

```markdown
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
```

- [ ] **Step 2: Verify SKILL.md is under 80 lines**

```bash
wc -l SKILL.md
```

Expected: under 80 lines.

- [ ] **Step 3: Commit**

```bash
git add SKILL.md
git commit -m "feat(audit-prep): rewrite SKILL.md as chain dispatcher, bump to v3.0"
```

---

## Task 5: Update VERSION

**Files:**
- Modify: `VERSION`

- [ ] **Step 1: Bump version**

```bash
echo "3.0" > VERSION
```

- [ ] **Step 2: Commit**

```bash
git add VERSION
git commit -m "chore(audit-prep): bump version to 3.0"
```

---

## Task 6: Write Solana Orchestrator

**Files:**
- Create: `references/chains/solana/orchestrator.md`

- [ ] **Step 1: Write the Solana orchestrator**

Create `references/chains/solana/orchestrator.md` with this content:

```markdown
# Solana (Rust/Anchor) Audit Preparation — Orchestrator

Orchestrate the Solana audit-prep pipeline for Rust/Anchor programs.
Do NOT perform analysis; discover files, dispatch agents, compile the scored report.

## Modes

- **Default:** full pipeline, all 10 phases + scan offer.
- **Single phase:** `coverage` | `quality` | `docs` | `hygiene` | `deps` | `practices` | `deploy` | `context` | `accounts` | `cpi`
- **`scan`:** static analysis only.
- **`--report <path>`:** write markdown report to file (no ANSI codes).
- **`--no-scan`:** skip scan offer.
- **`--scanner <tool>`:** run specific tool without prompting.
- **`--diff <ref>`:** scope to files changed since git ref.
- **`--ci`:** JSON output. Exit 0 if score >= threshold (default 75, `--min-score N`).

Note: `--fix` is not supported for Solana in this version.

## Report Format

Same format as EVM: clean markdown, phase tables with Status | Finding | Recommendation columns, score summary, Quick Wins. Include chain label "Solana (Rust/Anchor)" in the report header.

For `--report` markdown files: include the banner from the parent `SKILL.md` as an uncolored code block at the top.

## Execution

### Turn 0: Path Discovery and Project Selection

Read in parallel:
- **Glob:** `**/references/chains/solana/agents/testing-agent.md` → extract parent directory as `{chain_agents_path}`
- **Glob:** `**/references/shared-rules.md` → extract full path as `{shared_rules}`

Then ask the user where the project is:

```json
{
  "question": "Where is the Solana project you want to prepare for audit?",
  "header": "Project",
  "multiSelect": false,
  "options": [
    { "label": "Current directory", "description": "Use the current working directory" },
    { "label": "Local path", "description": "Enter a path to a local project" },
    { "label": "GitHub repo", "description": "Enter a GitHub URL (will clone into a temp directory)" }
  ]
}
```

If **Current directory**: use cwd as `{project_dir}`.
If **Local path**: user provides path → `{project_dir}`.
If **GitHub repo**: clone with `git clone <url> /tmp/audit-prep-<repo-name>` → `{project_dir}`.

### Turn 1: Discover and Prepare

Make these **parallel tool calls** in ONE message:
a. **Bash:** detect framework:
   ```bash
   ls {project_dir}/Anchor.toml 2>/dev/null && echo "FRAMEWORK=anchor" || echo "FRAMEWORK=native"
   cat {project_dir}/Anchor.toml 2>/dev/null | grep 'anchor-version\|version' | head -3
   ```
b. **Bash:** find in-scope `.rs` files under `programs/` (exclude `tests/`, `target/`):
   ```bash
   find {project_dir}/programs -name '*.rs' \
     ! -path '*/target/*' ! -path '*/tests/*' ! -name 'mod.rs' 2>/dev/null
   ```
   If `--diff <ref>`: `git diff --name-only <ref> -- '*.rs'` filtered to `programs/`.
c. **Bash:** find test files:
   ```bash
   find {project_dir}/tests -name '*.ts' -o -name '*.js' 2>/dev/null
   find {project_dir}/tests -name '*.rs' 2>/dev/null
   find {project_dir}/programs -path '*/tests/*.rs' 2>/dev/null
   ```
d. **Bash:** count total lines: `wc -l` on discovered source files
e. **Bash:** `mkdir -p {project_dir}/.audit-prep` → `{bundle_dir}` = `{project_dir}/.audit-prep`
f. **ToolSearch:** `mcp__sc-auditor` (for scan menu in Turn 4)

Then create 4 agent bundles in a **single Bash call**:

```bash
printf '%s\n' <in-scope-files> > {bundle_dir}/files.txt

# Agent A: Testing (Phases 1+2)
{
  printf 'framework: %s\nproject_dir: %s\n\n' "<fw>" "<dir>"
  echo "# Test files:"
  for f in <test-files>; do
    printf '%s (%s lines)\n' "$f" "$(wc -l < "$f")"
  done
  echo ""
  echo "# In-scope source files:"
  cat {bundle_dir}/files.txt
  echo ""
  cat {chain_agents_path}/testing-agent.md
  echo ""
  cat {shared_rules}
} > {bundle_dir}/agent-a.md

# Agent B: Source Analysis (Phases 3+4+6)
{
  printf 'project_dir: %s\n\n' "<dir>"
  echo "# In-scope source files:"
  cat {bundle_dir}/files.txt
  echo ""
  cat {chain_agents_path}/source-analysis-agent.md
  echo ""
  cat {shared_rules}
} > {bundle_dir}/agent-b.md

# Agent C: Infrastructure (Phases 5+7+8)
{
  printf 'framework: %s\nproject_dir: %s\n\n' "<fw>" "<dir>"
  cat {chain_agents_path}/infrastructure-agent.md
  echo ""
  cat {shared_rules}
} > {bundle_dir}/agent-c.md

# Agent D: Account Validation + CPI Safety (Phases 9+10)
{
  printf 'project_dir: %s\n\n' "<dir>"
  echo "# In-scope source files:"
  cat {bundle_dir}/files.txt
  echo ""
  cat {chain_agents_path}/account-validation-agent.md
  echo ""
  cat {shared_rules}
} > {bundle_dir}/agent-d.md

echo "=== Bundles ==="
wc -l {bundle_dir}/agent-*.md
```

Print: `<project> | Solana (Rust/Anchor) | <N> files, <M> lines`

### Turn 2: Spawn

**First**, create 4 tasks:

| Task | Subject | Active Form |
|------|---------|-------------|
| A | Test coverage & quality (Phases 1-2) | Analyzing test coverage & quality |
| B | Source code analysis (Phases 3, 4, 6) | Analyzing source code |
| C | Infrastructure checks (Phases 5, 7, 8) | Checking infrastructure |
| D | Account & CPI safety (Phases 9-10) | Checking account validation & CPI safety |

Use TaskCreate for each, then immediately set all 4 to `in_progress` via TaskUpdate.

**Then**, in the SAME message, spawn **4 parallel Agent calls:**

**Agent A: Testing (Phases 1 + 2):**
```
Read your full bundle at {bundle_dir}/agent-a.md.
Execute Phases 1 and 2 exactly as specified.
Output ONLY the PHASE/FAIL/PASS structured format from the shared rules.
Do NOT skip any phase. Do NOT add commentary or tables.
```

**Agent B: Source Analysis (Phases 3 + 4 + 6):**
```
Read your full bundle at {bundle_dir}/agent-b.md.
Execute Phases 3, 4, and 6 exactly as specified.
Use Grep and Read to analyze the source files listed in the bundle.
Do NOT read all source files at once; use targeted queries per check.
Output ONLY the PHASE/FAIL/PASS structured format from the shared rules.
Do NOT skip any phase. Do NOT perform vulnerability analysis.
```

**Agent C: Infrastructure (Phases 5 + 7 + 8):**
```
Read your full bundle at {bundle_dir}/agent-c.md.
Execute Phases 5, 7, and 8 exactly as specified.
Output ONLY the PHASE/FAIL/PASS structured format from the shared rules.
Do NOT skip any phase. Do NOT add commentary or tables.
```

**Agent D: Account Validation + CPI Safety (Phases 9 + 10):**
```
Read your full bundle at {bundle_dir}/agent-d.md.
Execute Phases 9 and 10 exactly as specified.
Use Grep and Read to analyze the source files listed in the bundle.
Do NOT read all source files at once; use targeted Grep queries.
Output ONLY the PHASE/FAIL/PASS structured format from the shared rules.
Do NOT skip any phase. Do NOT perform vulnerability analysis.
```

As each agent completes, mark its task as `completed` via TaskUpdate.

### Turn 3: Score and Report

**Parse** all 4 agents' output (Phases 1–10).

**Validate:** For each expected phase (1–10):
- Missing `PHASE N` marker → score = 0, add note "(not reported by agent)"

**Compute weighted score:**

| Phase | Weight |
|-------|--------|
| 1. Coverage | 12% |
| 2. Quality | 12% |
| 3. Documentation | 8% |
| 4. Hygiene | 8% |
| 5. Dependencies | 8% |
| 6. Best Practices | 12% |
| 7. Deployment | 8% |
| 8. Project Docs | 12% |
| 9. Account Validation | 10% |
| 10. CPI Safety | 10% |

**Verdict:** 90–100 Audit Ready | 75–89 Almost Ready | 50–74 Needs Work | <50 Not Ready
**Override:** If Phase 1 (Coverage) score < 90, verdict CANNOT be "Audit Ready"; cap at "Almost Ready (coverage below 90%)".

Render the report as clean markdown. Phase sections 9 and 10 are labeled "Solana: Account Validation" and "Solana: CPI Safety" to distinguish them from the shared phases.

End with Score Summary table (10 phases) and Quick Wins table (top 5 most impactful FAILs).

If `--report <path>`: write markdown to file (include banner as code block at top).
If `--ci`: JSON `{"chain": "solana", "score": N, "verdict": "...", "phases": [...], "findings": [...]}`.

### Turn 4: Scan Menu

Skip if `--no-scan`. If `--scanner <tool>`, run directly.

**Detection:**
```bash
echo "=== SCAN DETECTION ==="
which trident 2>/dev/null && echo "TRIDENT=yes" || echo "TRIDENT=no"
which soteria 2>/dev/null && echo "SOTERIA=yes" || echo "SOTERIA=no"
```

**Present the scan menu using AskUserQuestion with multiSelect: true:**

```json
{
  "question": "Which scanners do you want to run?",
  "header": "Bug Scan",
  "multiSelect": true,
  "options": [
    { "label": "Trident (extended fuzz)", "description": "Fuzz testing beyond Phase 2 estimate (installed / not installed)" },
    { "label": "Soteria", "description": "Solana static analyzer (installed / not installed)" },
    { "label": "Import custom scanner", "description": "Provide a CLI command to run your own scanner" }
  ]
}
```

Set each tool's description dynamically based on detection result.

**Tool execution:**
| Tool | Command |
|------|---------|
| Trident | `cd {project_dir} && trident fuzz 2>&1` (timeout 300s) |
| Soteria | `cd {project_dir} && soteria -analyzeAll 2>&1` (timeout 300s) |

Findings from scanners do NOT affect the audit-prep score.
```

- [ ] **Step 2: Verify file is under 500 lines**

```bash
wc -l references/chains/solana/orchestrator.md
```

Expected: under 500 lines.

- [ ] **Step 3: Commit**

```bash
git add references/chains/solana/orchestrator.md
git commit -m "feat(audit-prep): add Solana orchestrator (10-phase pipeline)"
```

---

## Task 7: Write Solana Testing Agent (Phases 1 + 2)

**Files:**
- Create: `references/chains/solana/agents/testing-agent.md`

- [ ] **Step 1: Write the file**

Create `references/chains/solana/agents/testing-agent.md`:

```markdown
# Solana Testing Agent: Phases 1 and 2

Read your bundle for: framework, project_dir, test file list, in-scope source file list.

## Phase 1: Test Coverage (12%)

### Step 1: Run coverage
```bash
cd {project_dir} && cargo llvm-cov --summary-only 2>&1
```
Timeout: 300s. If `cargo llvm-cov` is not installed, emit:
```
FAIL | no_coverage_tool | -10 | n/a
desc: cargo-llvm-cov not installed, coverage could not be measured
fix: Run: cargo install cargo-llvm-cov && cargo llvm-cov --summary-only
```
Then estimate from test file matching (see Step 2).

Extract per-program line and branch coverage percentages from output.

### Step 2: Match test files to programs
Compare in-scope source files (from bundle `files.txt`) against test files in the bundle.
A program has coverage if a test file exists that imports or references its program ID or module name.

### Step 3: Compiler health
```bash
cd {project_dir} && anchor build 2>&1 | grep -ci 'warning\[' 2>/dev/null || \
  cargo build 2>&1 | grep -ci 'warning\[' 2>/dev/null
```

### Scoring
- Base score = average branch coverage % (or estimated coverage if tool missing)
- If estimated: apply -10 confidence penalty
- Compiler warnings: -10 each (cap -30)
- Untested programs (no matching test file): -15 each (cap -45)

### Coverage threshold
If branch coverage < 90%, emit:
```
FAIL | below_threshold | -0 | n/a
desc: Branch coverage XX%, audit requires minimum 90%
fix: Add tests to reach 90%+ branch coverage before scheduling audit
```
(informational only — no extra deduction)

### Output:
```
PHASE 1 | Test Coverage | SCORE: 70/100

FAIL | below_threshold | -0 | n/a
desc: Branch coverage 70%, audit requires minimum 90%
fix: Add tests to reach 90%+ branch coverage before scheduling audit

FAIL | no_coverage | -15 | programs/vault/src/lib.rs
desc: No test file found for vault program
fix: Create tests/vault.ts with instruction tests

PASS | contract_coverage | programs/token/src/lib.rs
note: token program: 95% line, 91% branch

END PHASE 1
```

## Phase 2: Test Quality (12%)

Use Grep on test files. Do NOT read full test files into context.

### Grep checks (run in parallel):

| Check | Pattern | Path |
|-------|---------|------|
| Test count | `it\(["']\|#\[tokio::test\]\|#\[test\]` | tests/ and programs/**/tests/ |
| Assertions | `assert\|assert_eq!\|assert_err!\|should\.be\.rejected\|expect(` | tests/ |
| Edge cases | `u64::MAX\|u128::MAX\|Pubkey::default()\|0u64\|zero` | tests/ |
| Negative tests | `should\.be\.rejected\|assert_err!\|Error::\|\.is_err()` | tests/ |
| Access control | files or tests matching `*access*\|*unauthorized*\|*permission*` | tests/ |
| Bankrun/Mollusk | `bankrun\|mollusk\|BanksClient` | tests/ |
| Trident fuzz | `trident\|FuzzAccounts\|fuzz_instruction` | (project root) |

Compute: assertion_density = assertion_count / test_count.
Compute: negative_pct = negative_test_count / test_count * 100.

### Scoring
| Check | Condition | Deduction |
|-------|-----------|-----------|
| Edge cases | None found | -25 |
| Assertion density | < 2.0/test | -15 |
| Assertion density | < 1.0/test (replaces above) | -30 |
| Negative tests | < 20% of tests | -15 |
| Access control tests | None found | -10 |
| Trident fuzz present | Found | +5 (cap 100) |

Access control tests are required: every privileged instruction must have an unauthorized-caller test.

### Output:
```
PHASE 2 | Test Quality | SCORE: 70/100

FAIL | no_access_control_tests | -10 | n/a
desc: No tests found verifying unauthorized callers are rejected
fix: Add tests that call privileged instructions with a non-owner signer and assert rejection

FAIL | assertion_density | -15 | n/a
desc: 1.3 assertions/test (65/50), below 2.0 threshold
fix: Add more assert_eq! and assert_err! to thin tests

PASS | edge_cases
note: 18 edge case checks (u64::MAX, Pubkey::default())

PASS | negative_tests
note: 32% rejection tests (16/50 tests)

END PHASE 2
```

## Constraints
- Use Bash and Grep only
- Do NOT read source .rs files
- Do NOT perform security analysis
- Structured output only; no prose or tables
```

- [ ] **Step 2: Commit**

```bash
git add references/chains/solana/agents/testing-agent.md
git commit -m "feat(audit-prep): add Solana testing agent (Phases 1+2)"
```

---

## Task 8: Write Solana Source Analysis Agent (Phases 3 + 4 + 6)

**Files:**
- Create: `references/chains/solana/agents/source-analysis-agent.md`

- [ ] **Step 1: Write the file**

Create `references/chains/solana/agents/source-analysis-agent.md`:

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add references/chains/solana/agents/source-analysis-agent.md
git commit -m "feat(audit-prep): add Solana source analysis agent (Phases 3+4+6)"
```

---

## Task 9: Write Solana Infrastructure Agent (Phases 5 + 7 + 8)

**Files:**
- Create: `references/chains/solana/agents/infrastructure-agent.md`

- [ ] **Step 1: Write the file**

Create `references/chains/solana/agents/infrastructure-agent.md`:

```markdown
# Solana Infrastructure Agent: Phases 5, 7 and 8

You have: framework, project_dir, and Bash/Read/Glob/Grep tools.
Do NOT read source .rs files. Check project infrastructure only.

## Phase 5: Dependencies (8%)

### Step 1: Cargo audit
```bash
cd {project_dir} && cargo audit --json 2>&1
```
Parse JSON output for vulnerabilities. Only report production dependencies (not dev-dependencies).

### Step 2: Cargo.lock
Glob for `{project_dir}/Cargo.lock`.
Deduction: -10 if missing.

### Step 3: Toolchain pinning
```bash
cat {project_dir}/rust-toolchain.toml 2>/dev/null || cat {project_dir}/rust-toolchain 2>/dev/null
```
Deduction: -15 if neither file exists.

### Step 4: Anchor/Solana CLI version documentation
Grep in README.md and Makefile: `anchor.*version\|solana.*version\|anchor-cli\|solana-cli`
Deduction: -10 if neither Anchor nor Solana CLI version is documented.

### Scoring
| Check | Deduction |
|-------|-----------|
| Critical CVE (production) | -20 |
| High/moderate CVE (production) | -10 |
| Missing Cargo.lock | -10 |
| Missing rust-toolchain.toml | -15 |
| Anchor/Solana CLI versions undocumented | -10 |

Dev-only vulnerabilities = INFO, no deduction.

### Output:
```
PHASE 5 | Dependencies | SCORE: 75/100

FAIL | no_toolchain_pin | -15 | n/a
desc: rust-toolchain.toml not found; Rust version is unspecified
fix: Create rust-toolchain.toml with [toolchain] channel = "1.79.0"

PASS | no_cves
note: cargo audit found no vulnerabilities

PASS | cargo_lock
note: Cargo.lock present

END PHASE 5
```

## Phase 7: Deployment Readiness (8%)

### Check 1: Clean build
```bash
cd {project_dir} && anchor build 2>&1
```
Timeout 300s. Deduction: -50 if build fails.

### Check 2: Tests pass
```bash
cd {project_dir} && anchor test --skip-local-validator 2>&1
```
Timeout 300s. If this fails, try: `cargo test 2>&1`.
Deduction: -30 if any tests fail (report X/Y passed).

### Check 3: Deploy scripts
Glob for: `{project_dir}/scripts/deploy*`, `{project_dir}/migrations/deploy*`, `{project_dir}/deploy/`
Deduction: -30 if no deploy scripts found.

### Check 4: Upgrade authority documented
Grep in README.md, SECURITY.md, docs/: `upgrade.authority\|upgrade_authority\|multisig\|burned\|immutable`
Deduction: -20 if upgrade authority disposition not documented.

### Check 5: README setup instructions
Read README.md first 80 lines. Look for: `anchor build\|cargo build\|npm install\|yarn\|install`.
Deduction: -15 if no setup instructions found.

### Check 6: Git cleanliness
```bash
git -C {project_dir} status --short 2>&1
```
Deduction: -10 if uncommitted changes to `.rs`, `Anchor.toml`, or `Cargo.toml` files.

### Check 7: IDL generated
Glob for: `{project_dir}/target/idl/*.json`, `{project_dir}/idl/*.json`
Deduction: -10 if no IDL files found (Anchor projects only; skip for native programs).

## Phase 8: Project Documentation (12%)

### Check 1: Architecture overview (-30)
Read README.md. Check for system description, program relationships, or diagrams.
Also check `docs/` directory.

### Check 2: Trust assumptions (-25)
Check for SECURITY.md or security section in README.
Grep: `trust\|assumption\|admin\|privileged\|upgrade.authority\|centralization\|role`

### Check 3: System invariants (-20)
Grep: `invariant` in README.md, docs/, or source comments.

### Check 4: Known issues (-15)
Check for `KNOWN_ISSUES.md`, `known-issues.md`.
Grep in README: `known.issue\|known.limitation\|known.risk`

### Check 5: Previous audits (-10)
Glob: `audits/`, `audit-reports/`, `security/`
Grep in README: `audit\|security review`
For first-audit projects: skip this check.

### Check 6: Scope definition (-10)
Check for `scope.md`, `SCOPE.md`, `scope.json`.
Also check README for a "Scope" or "Programs" section listing in-scope programs.

### Check 7: Upgrade authority disposition (-15, required — not conditional)
Grep README, SECURITY.md, docs/: `upgrade.authority\|upgrade_authority\|multisig\|burned\|immutable`
If not found: flag it. Unlike EVM, upgrade authority is always required for Solana programs (it controls program bytecode).

### Output:
```
PHASE 8 | Project Documentation | SCORE: 40/100

FAIL | no_upgrade_authority | -15 | n/a
desc: Upgrade authority disposition not documented
fix: Document in SECURITY.md: who holds the upgrade key, multisig threshold, or confirm it is burned

FAIL | no_trust_model | -25 | n/a
desc: No trust assumptions or threat model documented
fix: Create SECURITY.md with admin roles, trust boundaries, and known risks

PASS | architecture
note: README contains system overview with program descriptions

END PHASE 8
```

## Constraints
- Do NOT read source .rs files
- Do NOT perform security or vulnerability analysis
- Output ONLY the structured PHASE/FAIL/PASS format
- No prose, tables, or summaries
```

- [ ] **Step 2: Commit**

```bash
git add references/chains/solana/agents/infrastructure-agent.md
git commit -m "feat(audit-prep): add Solana infrastructure agent (Phases 5+7+8)"
```

---

## Task 10: Write Solana Account Validation + CPI Safety Agent (Phases 9 + 10)

**Files:**
- Create: `references/chains/solana/agents/account-validation-agent.md`

- [ ] **Step 1: Write the file**

Create `references/chains/solana/agents/account-validation-agent.md`:

```markdown
# Solana Account Validation + CPI Safety Agent: Phases 9 and 10

You have: project_dir, in-scope file list (.rs files), and Grep + Read tools.

**CRITICAL: Do NOT read all source files at once. Use targeted Grep queries for each check.**

## Phase 9: Account Validation (10%)

### A1: PDA seeds undocumented
Grep: `seeds = \[` in `#[derive(Accounts)]` structs.
For each PDA declaration found, check for a `/// PDA seeds:` comment in the corresponding account struct definition.
Deduction: -10 per undocumented PDA (cap -30)
Auditors must be able to verify PDA derivation without reading all callsites.

### A2: Bump not stored on-chain
Grep: `seeds = \[` to find PDA accounts.
For each PDA account, check if the corresponding account struct has a `pub bump: u8` field.
Deduction: -5 per PDA without stored bump (cap -15)
Without a stored bump, programs must recompute it on every instruction, and bump-grinding attacks become possible.

### A3: `init_if_needed` without reinitialization guard
Grep: `init_if_needed`
For each match, read 10 lines of context (the full accounts struct constraint block).
If no `constraint` verifying the account is not already initialized is present, flag it.
Deduction: -15 each
`init_if_needed` without a guard allows an attacker to reinitialize an account and reset its state.

### A4: Duplicate mutable accounts (missing distinct-key constraint)
Grep: Instructions with 2 or more `mut` accounts of the same type.
Pattern: find `#[derive(Accounts)]` blocks with 2+ `#[account(mut` annotations.
For each such instruction, check for a `constraint = account_a.key() != account_b.key()` guard.
Deduction: -10 per instruction missing the distinct-key constraint (cap -20)

### A5: Raw AccountInfo for state accounts
Grep: `AccountInfo<'info>` in `#[derive(Accounts)]` structs.
For each match, read 5 lines of context. If used for program-owned state (not system_program, token_program, rent, or clock sysvars), flag it.
Deduction: -10 each (cap -20)
Anchor's `Account<'info, T>` performs automatic owner and discriminator checks. Raw `AccountInfo` does neither.

### Output:
```
PHASE 9 | Account Validation | SCORE: 60/100

FAIL | missing_pda_docs | -10 | programs/vault/src/state.rs:15
desc: UserVault PDA has no /// PDA seeds: comment
fix: Add /// PDA seeds: ["vault", user.key()] above the UserVault struct

FAIL | bump_not_stored | -5 | programs/vault/src/state.rs:15
desc: UserVault PDA does not store bump seed
fix: Add pub bump: u8 field to UserVault and populate it during init

FAIL | init_if_needed_unguarded | -15 | programs/vault/src/lib.rs:88
desc: init_if_needed used without a not-already-initialized constraint
fix: Add constraint = vault.deposited == 0 @ VaultError::AlreadyInitialized, or use init instead

PASS | no_duplicate_mutable_accounts
note: No instructions found with duplicate mutable accounts of the same type

END PHASE 9
```

## Phase 10: CPI Safety (10%)

### C1: Arbitrary CPI (no program ID validation)
Grep: `invoke\s*\(` and `invoke_signed\s*\(`
For each match, read 10 lines above. Check for `require_keys_eq!` or `if ctx.accounts.<program>.key() !=` validating the program ID before the invoke call.
Deduction: -20 each (cap -40)
Without program ID validation, an attacker can pass a malicious program that satisfies account constraints but executes different logic.

### C2: Missing program ID validation on CPI via CpiContext
Grep: `CpiContext::new\|CpiContext::new_with_signer`
For each match, read 10 lines above. Check for `require_keys_eq!` on the program account key.
If the target program is a well-known Anchor program imported directly (e.g., `anchor_spl::token::transfer`), skip this check (the import already pins the program ID).
Only flag cases where the program account comes from `ctx.accounts.*`.
Deduction: -15 each (cap -30)

### C3: Missing `.reload()` after CPI
Grep: `CpiContext::new\|invoke\s*\(` for CPI calls.
For each CPI call, read 15 lines after. Check for `.reload()` on any account that the CPI may have modified.
Flag only if the same account is READ after the CPI in the same instruction (i.e., stale data would cause incorrect behavior).
Deduction: -10 each (cap -20)

### Output:
```
PHASE 10 | CPI Safety | SCORE: 70/100

FAIL | arbitrary_cpi | -20 | programs/vault/src/lib.rs:112
desc: invoke() called without validating program ID beforehand
fix: Add require_keys_eq!(ctx.accounts.target_program.key(), expected::ID, VaultError::InvalidProgram) before invoke()

FAIL | missing_reload | -10 | programs/vault/src/lib.rs:130
desc: vault account read after CPI but .reload() not called
fix: Add ctx.accounts.vault.reload()? after the CpiContext call at line 128

PASS | no_cpi_context_arbitrary
note: All CpiContext calls use imported Anchor program IDs (anchor_spl::token)

END PHASE 10
```

## Constraints
- Use Grep and Read ONLY; no Bash commands
- Do NOT read all source files at once; use targeted queries
- Do NOT perform broader vulnerability analysis or threat modeling
- Output ONLY the structured PHASE/FAIL/PASS format
```

- [ ] **Step 2: Commit**

```bash
git add references/chains/solana/agents/account-validation-agent.md
git commit -m "feat(audit-prep): add Solana account validation + CPI safety agent (Phases 9+10)"
```

---

## Task 11: Write Solana Evals

**Files:**
- Create: `evals/solana/evals.json`
- Create: `evals/solana/grade.sh`

- [ ] **Step 1: Write evals.json**

Create `evals/solana/evals.json`:

```json
{
  "skill_name": "audit-prep",
  "chain": "solana",
  "evals": [
    {
      "id": 1,
      "name": "anchor-small-project",
      "prompt": "prepare this project for audit",
      "project_dir": "/path/to/your/anchor-project",
      "expected_output": "Full 10-phase audit readiness report for an Anchor project. Missing rust-toolchain.toml, undocumented PDAs, no deploy scripts.",
      "assertions": [
        {
          "id": "format-all-phases",
          "text": "All 10 phases are reported (PHASE 1 through PHASE 10)",
          "type": "programmatic",
          "check": "grep -c 'PHASE [0-9]\\+ |' should return 10"
        },
        {
          "id": "format-end-markers",
          "text": "All phases have END PHASE markers",
          "type": "programmatic",
          "check": "grep -c 'END PHASE' should return 10"
        },
        {
          "id": "format-fail-has-fix",
          "text": "Every FAIL line is followed by desc: and fix: lines",
          "type": "programmatic",
          "check": "Every FAIL block has both desc: and fix: on subsequent lines"
        },
        {
          "id": "detect-anchor",
          "text": "Framework detected as Anchor",
          "type": "programmatic",
          "check": "Output contains 'anchor' or 'Anchor' in project summary line"
        },
        {
          "id": "no-vuln-analysis",
          "text": "No vulnerability analysis in output",
          "type": "programmatic",
          "check": "Output does NOT contain '[H-0' or '[M-0' or 'vulnerability' or 'exploit'"
        },
        {
          "id": "deps-no-toolchain",
          "text": "Phase 5 flags missing rust-toolchain.toml",
          "type": "programmatic",
          "check": "Phase 5 output contains 'no_toolchain_pin' FAIL"
        },
        {
          "id": "account-phase-present",
          "text": "Phase 9 (Account Validation) is reported",
          "type": "programmatic",
          "check": "Output contains 'PHASE 9 | Account Validation'"
        },
        {
          "id": "cpi-phase-present",
          "text": "Phase 10 (CPI Safety) is reported",
          "type": "programmatic",
          "check": "Output contains 'PHASE 10 | CPI Safety'"
        },
        {
          "id": "quick-wins-present",
          "text": "Report ends with Quick Wins section",
          "type": "programmatic",
          "check": "Output contains 'Quick Wins'"
        },
        {
          "id": "upgrade-authority-checked",
          "text": "Phase 8 checks upgrade authority documentation",
          "type": "programmatic",
          "check": "Phase 8 output contains 'upgrade_authority' or 'no_upgrade_authority'"
        },
        {
          "id": "solana-chain-label",
          "text": "Report header identifies chain as Solana",
          "type": "programmatic",
          "check": "Output contains 'Solana' in project summary line"
        }
      ]
    },
    {
      "id": 2,
      "name": "anchor-multi-program",
      "prompt": "prepare this project for audit",
      "project_dir": "/path/to/your/multi-program-anchor-project",
      "expected_output": "Full 10-phase report for a multi-program Anchor project with CPI calls between programs. CPI safety issues flagged.",
      "assertions": [
        {
          "id": "format-all-phases",
          "text": "All 10 phases are reported",
          "type": "programmatic",
          "check": "grep -c 'PHASE [0-9]\\+ |' should return 10"
        },
        {
          "id": "cpi-safety-checks",
          "text": "Phase 10 runs CPI checks (finds results, not all PASS by default)",
          "type": "programmatic",
          "check": "Phase 10 output contains at least one FAIL or PASS line"
        },
        {
          "id": "no-vuln-analysis",
          "text": "No vulnerability analysis in output",
          "type": "programmatic",
          "check": "Output does NOT contain '[H-0' or '[M-0' or 'vulnerability' or 'exploit'"
        },
        {
          "id": "account-validation-checks",
          "text": "Phase 9 checks PDA documentation",
          "type": "programmatic",
          "check": "Phase 9 output contains 'pda' or 'bump' or 'init_if_needed' check"
        }
      ]
    }
  ]
}
```

- [ ] **Step 2: Write grade.sh**

Create `evals/solana/grade.sh`:

```bash
#!/bin/bash
# Grade audit-prep Solana eval output against assertions
# Usage: ./grade.sh <output_file> <eval_id>
#   output_file: concatenated agent outputs (agent-a through agent-d)
#   eval_id: 1 (anchor-small-project) or 2 (anchor-multi-program)

OUTPUT="$1"
EVAL_ID="${2:-1}"
PASSED=0
FAILED=0
TOTAL=0

check() {
  local id="$1" desc="$2" result="$3"
  TOTAL=$((TOTAL + 1))
  if [ "$result" = "pass" ]; then
    PASSED=$((PASSED + 1))
    printf '  \033[32mPASS\033[0m  %s: %s\n' "$id" "$desc"
  else
    FAILED=$((FAILED + 1))
    printf '  \033[31mFAIL\033[0m  %s: %s\n' "$id" "$desc"
  fi
}

echo ""
echo "=== Grading Solana eval $EVAL_ID ==="
echo ""

# --- Common assertions (both evals) ---

# All 10 phases present
count=$(grep -c 'PHASE [0-9][0-9]* |' "$OUTPUT" 2>/dev/null)
[ "$count" -ge 10 ] && check "format-all-phases" "All 10 phases reported" "pass" \
  || check "format-all-phases" "All 10 phases reported (got $count)" "fail"

# END markers
count=$(grep -c 'END PHASE' "$OUTPUT" 2>/dev/null)
[ "$count" -ge 10 ] && check "format-end-markers" "All END PHASE markers present" "pass" \
  || check "format-end-markers" "All END PHASE markers (got $count)" "fail"

# Every FAIL has desc: and fix:
fail_count=$(grep -c '^FAIL' "$OUTPUT" 2>/dev/null)
desc_count=$(grep -c '^desc:' "$OUTPUT" 2>/dev/null)
fix_count=$(grep -c '^fix:' "$OUTPUT" 2>/dev/null)
if [ "$fail_count" -gt 0 ] && [ "$desc_count" -ge "$fail_count" ] && [ "$fix_count" -ge "$fail_count" ]; then
  check "format-fail-has-fix" "Every FAIL has desc: and fix:" "pass"
else
  check "format-fail-has-fix" "FAIL/desc/fix mismatch ($fail_count/$desc_count/$fix_count)" "fail"
fi

# No vulnerability analysis
if grep -qi '\[H-0\|\[M-0\|vulnerability\|exploit' "$OUTPUT" 2>/dev/null; then
  check "no-vuln-analysis" "No vulnerability analysis" "fail"
else
  check "no-vuln-analysis" "No vulnerability analysis" "pass"
fi

# Quick Wins present
if grep -q 'Quick Wins' "$OUTPUT" 2>/dev/null; then
  check "quick-wins" "Quick Wins section present" "pass"
else
  check "quick-wins" "Quick Wins section present" "fail"
fi

# Phase 9 present
if grep -q 'PHASE 9 | Account Validation' "$OUTPUT" 2>/dev/null; then
  check "account-phase-present" "Phase 9 Account Validation present" "pass"
else
  check "account-phase-present" "Phase 9 Account Validation present" "fail"
fi

# Phase 10 present
if grep -q 'PHASE 10 | CPI Safety' "$OUTPUT" 2>/dev/null; then
  check "cpi-phase-present" "Phase 10 CPI Safety present" "pass"
else
  check "cpi-phase-present" "Phase 10 CPI Safety present" "fail"
fi

# Solana label in output
if grep -q 'Solana' "$OUTPUT" 2>/dev/null; then
  check "solana-chain-label" "Solana chain label present" "pass"
else
  check "solana-chain-label" "Solana chain label present" "fail"
fi

# Upgrade authority checked in Phase 8
if grep -q 'upgrade_authority\|no_upgrade_authority' "$OUTPUT" 2>/dev/null; then
  check "upgrade-authority-checked" "Upgrade authority check present" "pass"
else
  check "upgrade-authority-checked" "Upgrade authority check present" "fail"
fi

# --- Eval-specific assertions ---

if [ "$EVAL_ID" = "1" ]; then
  # Anchor detected
  if grep -qi 'anchor' "$OUTPUT" 2>/dev/null; then
    check "detect-anchor" "Framework detected as Anchor" "pass"
  else
    check "detect-anchor" "Framework detected as Anchor" "fail"
  fi

  # Missing rust-toolchain.toml flagged
  if grep -q 'no_toolchain_pin' "$OUTPUT" 2>/dev/null; then
    check "deps-no-toolchain" "Missing rust-toolchain.toml flagged" "pass"
  else
    check "deps-no-toolchain" "Missing rust-toolchain.toml flagged" "fail"
  fi

elif [ "$EVAL_ID" = "2" ]; then
  # CPI checks ran
  if awk '/PHASE 10/,/END PHASE 10/' "$OUTPUT" | grep -q 'FAIL\|PASS' 2>/dev/null; then
    check "cpi-safety-checks" "Phase 10 produced check results" "pass"
  else
    check "cpi-safety-checks" "Phase 10 produced check results" "fail"
  fi

  # Account validation checks ran
  if awk '/PHASE 9/,/END PHASE 9/' "$OUTPUT" | grep -qi 'pda\|bump\|init_if_needed' 2>/dev/null; then
    check "account-validation-checks" "Phase 9 checked PDA/bump/init_if_needed" "pass"
  else
    check "account-validation-checks" "Phase 9 checked PDA/bump/init_if_needed" "fail"
  fi
fi

# --- Summary ---
echo ""
printf '=== Results: %d/%d passed ' "$PASSED" "$TOTAL"
if [ "$FAILED" -eq 0 ]; then
  printf '\033[32m(100%%)\033[0m'
else
  pct=$((PASSED * 100 / TOTAL))
  printf '\033[31m(%d%%)\033[0m' "$pct"
fi
echo " ==="
echo ""
```

- [ ] **Step 3: Make grade.sh executable**

```bash
chmod +x evals/solana/grade.sh
```

- [ ] **Step 4: Commit**

```bash
git add evals/solana/evals.json evals/solana/grade.sh
git commit -m "feat(audit-prep): add Solana evals and grading script"
```

---

## Task 12: Update Documentation

**Files:**
- Modify: `audit-prep-skills/CLAUDE.md`
- Modify: `audit-prep-skills/README.md`
- Modify: `CLAUDE.md` (root)

- [ ] **Step 1: Update audit-prep-skills/CLAUDE.md structure section**

In `audit-prep-skills/CLAUDE.md`, replace the Structure section with:

```markdown
## Structure

```
audit-prep/           # Multi-chain audit preparation pipeline
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
```

- [ ] **Step 2: Update audit-prep-skills/README.md**

Find the existing phases table in the `## Skills > ### audit-prep` section (it starts with `| Phase | What it checks |`) and replace it with this two-chain version:

```markdown
| Phase | EVM checks | Solana checks |
|-------|-----------|---------------|
| 1. Test Coverage | forge/hardhat coverage | cargo llvm-cov coverage |
| 2. Test Quality | Assertion density, fuzz, fork tests | Assertion density, access control tests, Trident |
| 3. Documentation | NatSpec coverage | Rust `///` doc comments, `# Access Control` / `# Errors` sections |
| 4. Code Hygiene | TODOs, floating pragma, console imports | TODOs, direct arithmetic, `init_if_needed` |
| 5. Dependencies | npm/git submodule CVEs | cargo audit, Cargo.lock, rust-toolchain.toml |
| 6. Best Practices | SafeERC20, CEI, reentrancy guards | Raw AccountInfo, bump storage, signer validation |
| 7. Deployment | forge build, deploy scripts | anchor build, deploy scripts, upgrade authority |
| 8. Project Docs | Architecture, trust assumptions, scope | Same + upgrade authority (required, not conditional) |
| 9. Account Validation | — | PDA docs, bump on-chain, `init_if_needed` guard, duplicate mutable |
| 10. CPI Safety | — | Arbitrary CPI, program ID validation, `.reload()` |
```

Also find the `## Run` section and replace its step 2 description with:

```markdown
2. Run the full audit-prep pipeline:

```
/audit-prep
```

Claude will ask which chain (EVM or Solana), then which project to analyze.
```

- [ ] **Step 3: Update root CLAUDE.md**

In `CLAUDE.md`, find the `## audit-prep Skill` section. Replace the agent count line ("Spawn 3 parallel agents") in the Turn 2 row and the phases table with:

```markdown
| Turn | What Happens |
|------|-------------|
| 0 | Print banner, ask which chain (EVM or Solana) |
| 1 | Discover project files, detect framework, build agent bundles |
| 2 | Spawn 3 parallel agents (EVM) or 4 parallel agents (Solana) |
| 3 | Parse agent output, compute weighted score, render Audit Readiness Report |
| 4 | Optional: scan menu (chain-specific tools) |
```

And replace the EVM-only phases table with:

```markdown
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
```

- [ ] **Step 4: Commit all documentation updates**

```bash
cd /home/talfao/Dev/guides
git add audit-prep-skills/CLAUDE.md audit-prep-skills/README.md CLAUDE.md
git commit -m "docs: update CLAUDE.md and README to reflect multi-chain audit-prep structure"
```

---

## Final Verification

- [ ] **Confirm directory structure**

```bash
cd /home/talfao/Dev/guides/audit-prep-skills/audit-prep
find . -not -path './.git/*' -not -path './target/*' | sort
```

Expected structure matches the File Map at the top of this plan.

- [ ] **Confirm no old agent paths remain**

```bash
grep -r 'references/agents/' . --include='*.md'
```

Expected: no matches (all references now use `references/chains/<chain>/agents/`).

- [ ] **Confirm line counts are within limits**

```bash
wc -l SKILL.md references/chains/evm/orchestrator.md references/chains/solana/orchestrator.md \
       references/chains/solana/agents/*.md
```

Expected: all files under 500 lines.
