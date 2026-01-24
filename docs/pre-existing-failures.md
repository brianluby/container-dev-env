# Pre-Existing Test Failures

Documented during Feature 017 (Codebase Hardening) implementation.
These 7 failures exist in the test suite independent of any changes made in this feature.

**Date**: 2026-01-24
**Branch**: 017-codebase-hardening
**Verification**: `git diff HEAD -- src/agent/lib/usage.sh` returns empty (file unmodified)

---

## 1. test_checkpoint.bats: rollback restores file state

**File**: `tests/unit/test_checkpoint.bats`, line 46
**Assertion**: `[[ "${status}" -eq 0 ]]`
**Root cause**: `git stash pop` fails when the stash was created on a commit that has since changed. The test creates a stash, modifies the file, then attempts rollback — but the git stash apply conflicts with the working tree state.
**Output**:
```
Saved working directory and index state On main: checkpoint: 20260124T072106Z [file_edit] Before bad change
```

---

## 2-7. test_usage.bats: associative array + set -u incompatibility (6 failures)

**File**: `tests/unit/test_usage.bats`
**Affected tests**:
- test 283: `usage: compute_cost returns numeric value`
- test 284: `usage: compute_cost uses default pricing for unknown model`
- test 285: `usage: update_session_usage increments tokens`
- test 286: `usage: update_session_usage accumulates across calls`
- test 287: `usage: update_session_usage sets model and provider`
- test 288: `usage: get_session_usage text format shows tokens`
- test 289: `usage: get_session_usage json format is valid JSON` (1 passes: `get_session_usage fails for missing session`)

**Root cause**: `src/agent/lib/usage.sh` line 32 uses Bash associative array lookup with a default value:

```bash
local input_price="${MODEL_INPUT_PRICING[${model}]:-5.00}"
```

Under `set -u` (nounset), when the key does not exist in the associative array, Bash treats the subscript expression as an unbound variable reference before the `:-` default can take effect. Model names containing hyphens (e.g., `claude-sonnet-4-20250514`) trigger word-splitting in the subscript context, causing:

```
src/agent/lib/usage.sh: line 32: claude: unbound variable
```

**Fix required** (not in scope for Feature 017): Replace the associative array lookup with an explicit case statement or function, or use `${MODEL_INPUT_PRICING[$model]+${MODEL_INPUT_PRICING[$model]}}` with a separate default assignment:

```bash
local input_price="${MODEL_INPUT_PRICING[$model]+${MODEL_INPUT_PRICING[$model]}}"
input_price="${input_price:-5.00}"
```

Alternatively, quote the subscript and check key existence first:

```bash
if [[ -v "MODEL_INPUT_PRICING[$model]" ]]; then
    local input_price="${MODEL_INPUT_PRICING[$model]}"
else
    local input_price="5.00"
fi
```
