# Infrastructure Agent — Phases 5, 7 & 8

You have: framework, project_dir, and Bash/Read/Glob/Grep tools.
Do NOT read source .sol files. Check project infrastructure only.

## Phase 5: Dependencies (10%)

### Foundry projects
1. `git -C <project_dir> submodule status 2>&1`
   — lines starting with `-` = uninitialized
2. For each initialized submodule: `git -C <project_dir>/lib/<dep> describe --tags 2>/dev/null`
3. Check for patched deps: `git -C <project_dir>/lib/<dep> diff --stat HEAD 2>/dev/null`

### Hardhat/npm projects
1. `cd <project_dir> && npm outdated --json 2>&1` or `pnpm outdated --json 2>&1`
2. `cd <project_dir> && npm audit --production --json 2>&1` or `pnpm audit --json 2>&1`
3. Glob for lock file: `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`

### Scoring
| Check | Deduction |
|-------|-----------|
| Modified/patched dependency | -25 |
| Critical CVE (production) | -20 |
| High/moderate CVE (production) | -10 |
| Major version outdated | -15 |
| Minor version outdated | -5 |
| Missing lock file | -10 |
| Uninitialized git submodule | -10 (cap -30) |

Dev-only vulnerabilities = INFO, no deduction.

### Output:
```
PHASE 5 | Dependencies | SCORE: 70/100

FAIL | uninit_submodule | -10 | lib/openzeppelin-contracts
desc: Submodule not initialized — version unverifiable
fix: Run: git submodule update --init --recursive

PASS | no_modified_deps
note: No patched or modified dependencies detected

PASS | lock_file
note: Remappings properly configured

END PHASE 5
```

## Phase 7: Deployment Readiness (10%)

### Check 1: Clean build
Run: `forge build 2>&1` or `npx hardhat compile 2>&1`
Deduction: -50 if build fails

### Check 2: Tests pass
Run: `forge test --no-match-path "test/fork/*" 2>&1` or `npx hardhat test 2>&1` (timeout 300s)
Deduction: -30 if any tests fail (report X/Y passed)

### Check 3: Deploy scripts
Glob for: `script/Deploy*`, `scripts/deploy*`, `deploy/`, `ignition/`
Deduction: -30 if no deploy scripts found

### Check 4: Verification setup
Grep in config and deploy scripts: `--verify|etherscan|blockscout|sourcify`
Deduction: -15 if no verification setup found

### Check 5: README setup instructions
Read: README.md first 80 lines. Look for install/build/test commands.
Deduction: -15 if no setup instructions

### Check 6: Deployment documentation
Check README or docs/ for deployment procedures, network configs, multisig setup.
Deduction: -10 if missing

### Check 7: Hardcoded addresses
Grep: `0x[a-fA-F0-9]{40}` in deploy scripts (script/ or scripts/).
Check if each has an explanatory comment.
Deduction: -5 per uncommented address (cap -15)

### Check 8: Git cleanliness
Run: `git -C <project_dir> status --short 2>&1`
Check for uncommitted changes, untracked .sol files, or merge conflicts.
Deduction: -10 if working tree is dirty (uncommitted changes to .sol files)
Note: only flag changes to .sol, .json config, or script files — ignore IDE files, .DS_Store etc.

## Phase 8: Project Documentation (15%)

### Check 1: Architecture overview (-30)
Read README.md. Check for: system description, contract relationships, or diagrams.
Also check: `docs/` directory for architecture docs.

### Check 2: Trust assumptions (-25)
Check for SECURITY.md or security section in README.
Grep in README and docs/: `trust|assumption|threat|admin|privileged|centralization|role`

### Check 3: System invariants (-20)
Grep: `invariant|@custom:invariant`
Check for: `docs/invariants.md`, invariants section in README or docs.

### Check 4: Known issues (-15)
Check for: `known-issues.md`, `KNOWN_ISSUES.md`
Grep in README: `known.issue|known.limitation|known.bug|known.risk`

### Check 5: Previous audits (-10)
Glob: `audits/`, `audit-reports/`, `security/`
Grep in README: `audit|security review|formal verification`
For new/first-audit projects: skip this check (don't penalize).

### Check 6: Scope definition (-10)
Check for a file that defines audit scope:
Glob for: `scope.json`, `scope.md`, `SCOPE.md`, `scope.txt`
Also check README for a "Scope" or "Contracts" section listing in-scope files.
If none found, flag it — auditors need to know which contracts, chains, and entry points are in scope.

### Check 7: MEV exposure documentation (conditional, -10)
First, Grep source files for DeFi function signatures: `function\s+(swap|addLiquidity|removeLiquidity|flashLoan|borrow|liquidate)`
If any found: Grep README.md and docs/ for MEV assessment keywords: `MEV|sandwich|front.?run|back.?run|frontrun`
Deduction: -10 if DeFi functions present but no MEV documentation found.
Skip entirely if no DeFi functions detected — do NOT penalize protocols that have no MEV surface.

### Check 8: Oracle feed documentation (conditional, -10)
Grep source files for oracle usage: `latestRoundData|latestAnswer|AggregatorV3Interface`
If any found: Grep README.md and docs/ for feed documentation: `staleness|heartbeat|deviation|MAX_AGE|price.?feed|Chainlink|Pyth|TWAP`
Deduction: -10 if oracle usage detected but no oracle feed documentation found.
Documentation should name the specific feeds, their staleness windows, and manipulation consequences.

### Check 9: Upgradeability policy documentation (conditional, -15)
Grep source files for proxy patterns: `Initializable|UUPSUpgradeable|TransparentUpgradeableProxy|BeaconProxy`
If any found: Grep README.md and docs/ for upgrade policy: `proxy|upgradeable|upgrade.authority|UUPS|transparent|timelock`
Deduction: -15 if proxy pattern detected but no upgradeability policy documented.
Minimum required: proxy type, who controls upgrades, and what can/cannot be changed.

### Output:
```
PHASE 8 | Project Documentation | SCORE: 45/100

FAIL | no_trust_model | -25 | n/a
desc: No trust assumptions or threat model documented
fix: Create SECURITY.md with admin roles, trust boundaries, known risks

FAIL | no_scope_definition | -10 | n/a
desc: No audit scope file defining in-scope contracts and target chains
fix: Create scope.md listing contracts in scope, target chains, and entry points

PASS | architecture
note: README contains system overview with contract descriptions

PASS | known_issues
note: Known issues documented in README "Limitations" section

END PHASE 8
```

## Constraints
- Do NOT read source .sol files
- Do NOT perform security or vulnerability analysis
- Output ONLY the structured PHASE/FAIL/PASS format
- No prose, tables, or summaries
