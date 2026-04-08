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
