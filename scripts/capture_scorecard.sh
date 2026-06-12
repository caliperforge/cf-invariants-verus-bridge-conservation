#!/usr/bin/env bash
# capture_scorecard.sh — parse echidna campaign output → scorecard.{json,md}.
#
# Usage:
#   capture_scorecard.sh \
#     --campaign echidna --leg clean|planted \
#     --invariant INV-CONS-bridge-balance \
#     --input .campaign-out/echidna-<leg>.out \
#     --out-dir findings/INV-CONS-bridge-balance/<leg>
#
# Strips ANSI, counts violated assertions, captures the shrunk counterexample
# sequence (if any), and writes scorecard.json + scorecard.md into out-dir.
#
# CI semantics: this script does NOT decide pass/fail. The CI workflow reads
# the scorecard.json and asserts the leg-appropriate violation count
# (clean → 0, planted → ≥1).

set -euo pipefail

CAMPAIGN=""
LEG=""
INVARIANT=""
INPUT=""
OUT_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --campaign)  CAMPAIGN="$2"; shift 2 ;;
        --leg)       LEG="$2"; shift 2 ;;
        --invariant) INVARIANT="$2"; shift 2 ;;
        --input)     INPUT="$2"; shift 2 ;;
        --out-dir)   OUT_DIR="$2"; shift 2 ;;
        *) echo "unknown arg: $1" >&2; exit 2 ;;
    esac
done

[[ -z "$CAMPAIGN" || -z "$LEG" || -z "$INVARIANT" || -z "$INPUT" || -z "$OUT_DIR" ]] && {
    echo "missing required arg (campaign / leg / invariant / input / out-dir)" >&2
    exit 2
}

if [[ ! -f "$INPUT" ]]; then
    echo "input not found: $INPUT — was the campaign run?" >&2
    exit 3
fi

mkdir -p "$OUT_DIR"

# ANSI-strip.
STRIPPED=$(sed -E 's/\x1B\[[0-9;]*[A-Za-z]//g' "$INPUT")

# Count violations. Echidna 2.x prints "failed!" or "FAILED!" against the
# violated property name; a clean run prints "passing" or "passed".
VIOLATIONS=$(printf '%s\n' "$STRIPPED" | grep -E -c 'failed!|FAILED' || true)

# Extract the shrunk call sequence, if present. Echidna prints a "Call
# sequence:" block followed by a few indented lines.
CALL_SEQUENCE=$(printf '%s\n' "$STRIPPED" | awk '/Call sequence:/{flag=1;next} flag && /^[[:space:]]/{print; next} flag{exit}' || true)

# Test count.
TEST_COUNT=$(printf '%s\n' "$STRIPPED" | grep -E -o 'tests:[[:space:]]*[0-9]+' | tail -1 | grep -E -o '[0-9]+' || echo "0")

# Timestamp from input mtime. Portable across macOS (BSD `date -r`) and
# Linux/GNU (`date -r` accepting a file path) — both emit ISO-8601 UTC.
TS=$(date -u -r "$INPUT" +%FT%TZ 2>/dev/null || echo "unknown")

cat > "$OUT_DIR/scorecard.json" <<EOF
{
  "campaign": "$CAMPAIGN",
  "leg": "$LEG",
  "invariant": "$INVARIANT",
  "invariants_violated": $VIOLATIONS,
  "tests_run": $TEST_COUNT,
  "captured_at": "$TS",
  "expected_violations": $( [[ "$LEG" == "clean" ]] && echo 0 || echo 1 ),
  "outcome": "$( [[ "$LEG" == "clean" && "$VIOLATIONS" -eq 0 ]] && echo expected \
                 || ( [[ "$LEG" == "planted" && "$VIOLATIONS" -gt 0 ]] && echo expected \
                 || echo unexpected ) )"
}
EOF

{
    echo "# Scorecard — $INVARIANT (leg: $LEG)"
    echo
    echo "**Campaign:** $CAMPAIGN"
    echo "**Leg:** $LEG"
    echo "**Captured:** $TS"
    echo
    echo "| Field | Value |"
    echo "|-------|-------|"
    echo "| invariants_violated | $VIOLATIONS |"
    echo "| tests_run | $TEST_COUNT |"
    echo "| expected_violations | $( [[ "$LEG" == "clean" ]] && echo 0 || echo "≥1" ) |"
    echo
    if [[ -n "$CALL_SEQUENCE" ]]; then
        echo "## Shrunk counterexample"
        echo
        echo '```'
        echo "$CALL_SEQUENCE"
        echo '```'
    else
        echo "## Shrunk counterexample"
        echo
        echo "_(none — campaign reported no violation)_"
    fi
} > "$OUT_DIR/scorecard.md"

echo "scorecard written: $OUT_DIR/scorecard.{json,md}  (violations: $VIOLATIONS)"
