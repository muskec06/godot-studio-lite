#!/bin/bash
# fal.ai cost helpers, shared by fal-budget.sh and tools/fal-cost.sh.
# Source after lib.sh (needs ROOT, cfg, json_get, INPUT).

FAL_MODELS="$ROOT/tools/fal-models.tsv"
FAL_LEDGER="$ROOT/production/asset-ledger.tsv"

# fal_endpoint -> the longest endpoint from fal-models.tsv that appears in
# $INPUT as a quoted string. Longest wins so "x/edit" beats "x". Empty if none.
fal_endpoint() {
  local best="" ep
  while IFS="$(printf '\t')" read -r ep _rest; do
    case "$ep" in ''|'#'*|endpoint) continue ;; esac
    case "$INPUT" in
      *"\"$ep\""*) [ ${#ep} -gt ${#best} ] && best="$ep" ;;
    esac
  done < "$FAL_MODELS"
  printf '%s' "$best"
}

# fal_model_field ENDPOINT COLUMN(2=role 3=unit 4=price)
fal_model_field() {
  awk -F'\t' -v e="$1" -v c="$2" '$1==e{print $c; exit}' "$FAL_MODELS" 2>/dev/null
}

# fal_estimate ENDPOINT -> estimated USD for the call described by $INPUT.
# Reads num_images, resolution, duration-like fields when present. Errs high.
fal_estimate() {
  local ep="$1" unit price n res f secs ms
  unit="$(fal_model_field "$ep" 3)"; price="$(fal_model_field "$ep" 4)"
  [ -n "$price" ] || { echo "0"; return; }
  case "$unit" in
    image)
      n="$(json_get num_images)"; case "$n" in ''|*[!0-9]*) n=1 ;; esac
      res="$(json_get resolution)"
      case "$res" in 0.5K|0.5k) f=0.75 ;; 2K|2k) f=1.5 ;; 4K|4k) f=2 ;; *) f=1 ;; esac
      awk -v p="$price" -v n="$n" -v f="$f" 'BEGIN{printf "%.4f", p*n*f}' ;;
    second)
      secs="$(json_get duration_seconds)"; [ -n "$secs" ] || secs="$(json_get duration)"
      case "$secs" in ''|*[!0-9.]*) secs=10 ;; esac
      awk -v p="$price" -v s="$secs" 'BEGIN{printf "%.4f", p*s}' ;;
    minute)
      ms="$(json_get music_length_ms)"
      if [ -n "$ms" ]; then secs=$(awk -v m="$ms" 'BEGIN{print m/1000}')
      else secs="$(json_get duration)"; fi
      case "$secs" in ''|*[!0-9.]*) secs=60 ;; esac
      awk -v p="$price" -v s="$secs" 'BEGIN{m=int((s+59)/60); if(m<1)m=1; printf "%.4f", p*m}' ;;
    *)
      awk -v p="$price" 'BEGIN{printf "%.4f", p}' ;;
  esac
}

# fal_spent -> total estimated USD in the ledger.
fal_spent() {
  awk -F'\t' 'NR>1 && $3!="" {s+=$3} END{printf "%.2f", s+0}' "$FAL_LEDGER" 2>/dev/null || printf '0.00'
}

# fal_ledger_add ENDPOINT COST NOTE
fal_ledger_add() {
  if [ ! -f "$FAL_LEDGER" ]; then
    mkdir -p "$(dirname "$FAL_LEDGER")"
    printf 'date\tendpoint\test_usd\tnote\n' > "$FAL_LEDGER"
  fi
  printf '%s\t%s\t%s\t%s\n' "$(date '+%Y-%m-%d %H:%M')" "$1" "$2" "$3" >> "$FAL_LEDGER"
}
