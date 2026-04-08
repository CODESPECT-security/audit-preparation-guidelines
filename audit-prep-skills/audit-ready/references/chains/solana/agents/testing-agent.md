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
