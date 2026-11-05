#!/bin/bash
# Asset generation spend, from production/asset-ledger.tsv (estimates).
#   bash tools/fal-cost.sh                     spent / budget / remaining
#   bash tools/fal-cost.sh estimate <endpoint> [count] [resolution|seconds]
#   bash tools/fal-cost.sh models              the allowed models and prices
set -u
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.claude/hooks/lib.sh"
. "$ROOT/.claude/hooks/fal-lib.sh"

case "${1:-status}" in
  status)
    b="$(cfg asset_budget_usd 20)"; s="$(fal_spent)"
    awk -v s="$s" -v b="$b" 'BEGIN{printf "assets: ~$%.2f spent of $%.2f (~$%.2f left)\n", s, b, b-s}'
    ;;
  estimate)
    ep="${2:-}"; n="${3:-1}"; x="${4:-}"
    [ -n "$(fal_model_field "$ep" 4)" ] || { echo "unknown endpoint: $ep (see: bash tools/fal-cost.sh models)"; exit 2; }
    INPUT="{\"endpoint\":\"$ep\",\"num_images\":1,\"resolution\":\"$x\",\"duration\":\"$x\"}"
    one="$(fal_estimate "$ep")"
    awk -v o="$one" -v n="$n" 'BEGIN{printf "~$%.2f (%d × ~$%.3f)\n", o*n, n, o}'
    ;;
  models)
    awk -F'\t' 'NR>1 && $1!~/^#/ && $1!="endpoint" && $1!="" {printf "%-38s %-11s $%s/%s (checked %s)\n", $1, $2, $4, $3, $5}' "$FAL_MODELS"
    ;;
  *) echo "usage: fal-cost.sh [status|estimate <endpoint> [count] [res|seconds]|models]"; exit 2 ;;
esac
