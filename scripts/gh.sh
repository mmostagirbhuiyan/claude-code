#!/usr/bin/env bash
set -euo pipefail

# Wrapper around gh CLI that only allows specific subcommands and flags.
#
# Usage:
#   ./scripts/gh.sh issue view 123
#   ./scripts/gh.sh issue view 123 --comments
#   ./scripts/gh.sh issue list --state open --limit 20
#   ./scripts/gh.sh search issues "search query" --limit 10
#   ./scripts/gh.sh label list --limit 100

ALLOWED_FLAGS=(--comments --state --limit --label)

SUB1="${1:-}"
SUB2="${2:-}"
CMD="$SUB1 $SUB2"
case "$CMD" in
  "issue view"|"issue list"|"search issues"|"label list")
    ;;
  *)
    exit 1
    ;;
esac

shift 2
for arg in "$@"; do
  if [[ "$arg" == -* ]]; then
    flag="${arg%%=*}"
    matched=false
    for allowed in "${ALLOWED_FLAGS[@]}"; do
      if [[ "$flag" == "$allowed" ]]; then
        matched=true
        break
      fi
    done
    if [[ "$matched" == false ]]; then
      exit 1
    fi
  fi
done

gh "$SUB1" "$SUB2" "$@"
