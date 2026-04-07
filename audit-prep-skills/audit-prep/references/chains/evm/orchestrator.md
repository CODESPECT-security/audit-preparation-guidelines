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

If `--report <path>`: write the markdown to the specified file path (include banner from SKILL.md as code block at top).
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
