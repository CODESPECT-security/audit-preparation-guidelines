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
