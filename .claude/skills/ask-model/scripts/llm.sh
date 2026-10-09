#!/usr/bin/env bash
# llm.sh — query non-Claude models through OpenRouter (second opinions / comparisons).
#
#   llm.sh <alias|vendor/model-id>  < prompt      one model
#   llm.sh compare [alias ...]      < prompt      several in parallel (default: gpt gemini grok deepseek)
#   llm.sh models [filter]                        live model IDs, newest first (no key needed)
#   llm.sh aliases                                the alias table below
#
# The prompt is read from STDIN so quotes, newlines, and `$` in it are never shell-interpreted
# (the old per-model commands spliced $ARGUMENTS into a JSON string and broke on any quote).
# Aliases point at OpenRouter's self-updating `~vendor/family-latest` IDs, so they don't rot
# the way pinned IDs (gpt-4, gemini-pro-1.5, llama-3.1-sonar…) did.
# Key: OPENROUTER_API_KEY from the environment, else sourced from ~/.secrets.env.
set -euo pipefail

API="https://openrouter.ai/api/v1"

declare -A ALIAS=(
  [gpt]='~openai/gpt-sol-latest'
  [gpt-astra]='~openai/gpt-astra-latest'
  [gpt-terra]='~openai/gpt-terra-latest'
  [gpt-luna]='~openai/gpt-luna-latest'
  [gpt-mini]='~openai/gpt-mini-latest'
  [gemini]='~google/gemini-pro-latest'
  [gemini-flash]='~google/gemini-flash-latest'
  [grok]='~x-ai/grok-latest'
  [deepseek]='~deepseek/deepseek-pro-latest'
  [deepseek-flash]='~deepseek/deepseek-flash-latest'
  [kimi]='~moonshotai/kimi-latest'
  [glm]='~z-ai/glm-latest'
  [perplexity]='perplexity/sonar-pro'
  [perplexity-reasoning]='perplexity/sonar-reasoning-pro'
  [perplexity-deep]='perplexity/sonar-deep-research'
  [opus]='~anthropic/claude-opus-latest'
  [sonnet]='~anthropic/claude-sonnet-latest'
)
DEFAULT_COMPARE=(gpt gemini grok deepseek)

die() { printf '%s\n' "$1" >&2; exit "${2:-1}"; }

resolve() {  # alias → model id; anything containing "/" passes through as a full ID
  local a="$1"
  if [[ "$a" == */* ]]; then printf '%s' "$a"; return; fi
  [[ -n "${ALIAS[$a]:-}" ]] || die "Unknown model alias '$a'. Run: llm.sh aliases (or pass a full vendor/model ID; see llm.sh models)." 2
  printf '%s' "${ALIAS[$a]}"
}

load_key() {
  if [[ -z "${OPENROUTER_API_KEY:-}" && -r "$HOME/.secrets.env" ]]; then
    set -a; # shellcheck disable=SC1091
    . "$HOME/.secrets.env"; set +a
  fi
  [[ -n "${OPENROUTER_API_KEY:-}" ]] || die "OPENROUTER_API_KEY is not set.
Add it to ~/.secrets.env (create with: install -m 600 /dev/null ~/.secrets.env), one line:
  OPENROUTER_API_KEY=sk-or-...
Get a key at https://openrouter.ai/keys . Never export it from ~/.bashrc in plain text." 3
}

ask() {  # $1=label $2=model-id $3=prompt-file → prints a framed answer
  local label="$1" model="$2" pfile="$3" payload resp content used cost err
  payload="$(jq -n --arg m "$model" --rawfile p "$pfile" \
    '{model:$m, messages:[{role:"user",content:$p}], usage:{include:true}}')"
  # Key goes in via a file descriptor, not argv, so it never shows up in `ps`.
  resp="$(curl -sS --max-time "${LLM_TIMEOUT:-300}" "$API/chat/completions" \
    -H @<(printf 'Authorization: Bearer %s\n' "$OPENROUTER_API_KEY") \
    -H 'Content-Type: application/json' \
    -H 'HTTP-Referer: https://github.com/akhil-p-git/claude-code-config' \
    -H 'X-Title: Claude Code ask-model' \
    --data-binary @- <<<"$payload" 2>&1)" || { printf '── %s (%s) ── request failed: %s\n\n' "$label" "$model" "$resp"; return 1; }
  err="$(jq -r '.error.message // empty' <<<"$resp" 2>/dev/null || true)"
  if [[ -n "$err" ]]; then printf '── %s (%s) ── API error: %s\n\n' "$label" "$model" "$err"; return 1; fi
  content="$(jq -r '.choices[0].message.content // empty' <<<"$resp" 2>/dev/null || true)"
  used="$(jq -r '.model // empty' <<<"$resp" 2>/dev/null || true)"
  cost="$(jq -r '.usage.cost // empty' <<<"$resp" 2>/dev/null || true)"
  [[ -n "$content" ]] || { printf '── %s (%s) ── empty response: %s\n\n' "$label" "$model" "${resp:0:400}"; return 1; }
  printf '── %s → %s%s ──\n%s\n\n' "$label" "${used:-$model}" "${cost:+ · \$$cost}" "$content"
}

cmd="${1:-}"; [[ -n "$cmd" ]] || die "usage: llm.sh <alias|vendor/model> | compare [aliases…] | models [filter] | aliases  (prompt on stdin)" 2
shift || true

case "$cmd" in
  aliases)
    for k in "${!ALIAS[@]}"; do printf '%-22s %s\n' "$k" "${ALIAS[$k]}"; done | sort
    ;;
  models)
    curl -sS --max-time 30 "$API/models" | jq -r --arg f "${1:-}" '
      .data | sort_by(-.created) | .[]
      | select(.id | test(":batch$") | not)
      | select(($f == "") or (.id | ascii_downcase | contains($f | ascii_downcase)))
      | def permtok(p): ((p // "0") | tonumber) * 1e6 | . * 100 | round / 100;
        "\(.created | todate[:10])  \(.id)  ($\(permtok(.pricing.prompt))/$\(permtok(.pricing.completion)) per M tok)"' \
      | head -n "${LLM_MODELS_LIMIT:-40}"
    ;;
  compare)
    load_key
    targets=("$@"); [[ ${#targets[@]} -gt 0 ]] || targets=("${DEFAULT_COMPARE[@]}")
    tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
    cat > "$tmp/prompt"; [[ -s "$tmp/prompt" ]] || die "Empty prompt: pipe the question on stdin." 2
    i=0
    for t in "${targets[@]}"; do
      m="$(resolve "$t")"
      ( ask "$t" "$m" "$tmp/prompt" > "$tmp/out.$i" 2>&1 || true ) &
      i=$((i+1))
    done
    wait
    for ((j=0; j<i; j++)); do cat "$tmp/out.$j"; done
    ;;
  *)
    load_key
    m="$(resolve "$cmd")"
    tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
    cat > "$tmp/prompt"; [[ -s "$tmp/prompt" ]] || die "Empty prompt: pipe the question on stdin." 2
    ask "$cmd" "$m" "$tmp/prompt"
    ;;
esac
