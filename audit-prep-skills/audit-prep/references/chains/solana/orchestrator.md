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

Render the report as clean markdown. Phase sections 9 and 10 are labeled "Solana: Account Validation" and "Solana: CPI Safety" in the report to distinguish them from the shared phases.

End with Score Summary table (10 phases) and Quick Wins table (top 5 most impactful FAILs).

If `--report <path>`: write markdown to file (include banner from SKILL.md as code block at top).
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
