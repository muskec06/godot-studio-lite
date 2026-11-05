#!/bin/bash
# fal.ai spend guard for the paid MCP tools (run_model, submit_job).
#   bash fal-budget.sh pre   PreToolUse:  refuse unlisted models and calls that
#                            would push estimated spend past asset_budget_usd
#   bash fal-budget.sh post  PostToolUse: record the call in production/asset-ledger.tsv
# Estimates come from tools/fal-models.tsv; they err high and are not a bill.
# The real bill is on https://fal.ai/dashboard/usage.
# exit 0 = allow · exit 2 = refuse (stderr shown to Claude)
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
. "$(dirname "${BASH_SOURCE[0]}")/fal-lib.sh"
INPUT="$(cat 2>/dev/null)"
phase="${1:-pre}"

ep="$(fal_endpoint)"

if [ "$phase" = "post" ]; then
  [ -n "$ep" ] || exit 0
  fal_ledger_add "$ep" "$(fal_estimate "$ep")" "$(json_get tool_name)"
  exit 0
fi

if [ -z "$ep" ]; then
  {
    echo "fal-budget: this call names no model listed in tools/fal-models.tsv, so it was not run."
    echo "Allowed: $(awk -F'\t' 'NR>1 && $1!~/^#/ && $1!="endpoint" && $1!="" {printf "%s ", $1}' "$FAL_MODELS")"
    echo "To use another model: check its fal.ai page shows \"Commercial use\" and its price, then ask the user to add a row."
  } >&2
  exit 2
fi

budget="$(cfg asset_budget_usd 20)"
spent="$(fal_spent)"
cost="$(fal_estimate "$ep")"
over="$(awk -v s="$spent" -v c="$cost" -v b="$budget" 'BEGIN{print (s+c>b)?1:0}')"
if [ "$over" = "1" ]; then
  echo "fal-budget: refused. Spent ~\$${spent} of \$${budget}; this call (${ep}) is ~\$${cost}. Ask the user to raise asset_budget_usd in project.yaml or skip it." >&2
  exit 2
fi
exit 0
