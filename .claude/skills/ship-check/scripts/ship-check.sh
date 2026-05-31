#!/usr/bin/env bash
# Pre-push quality gate: secrets, lint, type-check, tests, dependency audit.
# Runs every applicable gate (does not stop on first failure) and exits non-zero
# if any gate failed. Operates on the current working directory.
set -uo pipefail

FAILED=0
run() { # run "<label>" <command...>
  local label="$1"; shift
  echo "── $label"
  if "$@"; then
    echo "  ✓ $label"
  else
    echo "  ✗ $label (exit $?)"
    FAILED=1
  fi
}
skip() { echo "── $1"; echo "  ⚠ SKIPPED — $2"; }
have() { command -v "$1" >/dev/null 2>&1; }

echo "ship-check in: $(pwd)"
echo

# ── 1. Secrets ────────────────────────────────────────────────────────────
echo "== Secrets =="
if git rev-parse --git-dir >/dev/null 2>&1; then
  STAGED=$(git diff --cached --name-only 2>/dev/null)
  BAD=$(printf '%s\n' "$STAGED" | grep -iE '(^|/)\.env($|\.)|\.(key|pem|p12|pfx)$|(^|/)secrets/' || true)
  if [ -n "$BAD" ]; then
    echo "  ✗ secret-like files staged:"; printf '    %s\n' $BAD; FAILED=1
  else
    echo "  ✓ no secret-like files staged"
  fi
  if have gitleaks; then
    run "gitleaks" gitleaks detect --no-banner --redact -v
  else
    skip "gitleaks" "not installed (install: paru -S gitleaks)"
  fi
  # Lightweight pattern grep over the working diff
  if git diff HEAD 2>/dev/null | grep -nE 'AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|(api[_-]?key|secret|token|password)[[:space:]]*[=:][[:space:]]*[A-Za-z0-9/_+-]{16,}' | grep -v '\.example' >/tmp/_sc_secrets 2>/dev/null; then
    echo "  ✗ possible secret in diff:"; sed 's/^/    /' /tmp/_sc_secrets | head -5; FAILED=1
  else
    echo "  ✓ no obvious secret patterns in diff"
  fi
  rm -f /tmp/_sc_secrets
else
  skip "secrets" "not a git repo"
fi
echo

# ── 2. JS / TS ────────────────────────────────────────────────────────────
if [ -f package.json ]; then
  echo "== JavaScript / TypeScript =="
  if [ -f pnpm-lock.yaml ]; then PM=pnpm; elif [ -f yarn.lock ]; then PM=yarn; elif [ -f bun.lockb ]; then PM=bun; else PM=npm; fi
  echo "  package manager: $PM"
  has_script() { node -e "process.exit(require('./package.json').scripts?.['$1']?0:1)" 2>/dev/null; }
  if has_script lint; then run "lint" $PM run lint; else skip "lint" "no 'lint' script"; fi
  if [ -f tsconfig.json ]; then
    if have npx; then run "type-check" npx --no-install tsc --noEmit; else skip "type-check" "npx unavailable"; fi
  else
    skip "type-check" "no tsconfig.json"
  fi
  if has_script test; then
    if [ "$PM" = npm ]; then run "tests" npm test --silent; else run "tests" $PM test; fi
  else
    skip "tests" "no 'test' script"
  fi
  case "$PM" in
    npm)  run "audit" npm audit --omit=dev --audit-level=high ;;
    pnpm) run "audit" pnpm audit --prod --audit-level high ;;
    yarn) run "audit" yarn npm audit --severity high ;;
    bun)  skip "audit" "bun has no audit; run 'npm audit' if needed" ;;
  esac
  echo
fi

# ── 3. Python ─────────────────────────────────────────────────────────────
if [ -f pyproject.toml ] || [ -f requirements.txt ] || ls ./*.py >/dev/null 2>&1; then
  echo "== Python =="
  if have ruff; then run "ruff" ruff check .; else skip "ruff" "not installed (pip install ruff)"; fi
  if have mypy; then run "mypy" mypy .; else skip "mypy" "not installed (pip install mypy)"; fi
  if have pytest; then run "pytest" pytest -q; else skip "pytest" "not installed (pip install pytest)"; fi
  if have pip-audit; then run "pip-audit" pip-audit; else skip "pip-audit" "not installed (pip install pip-audit)"; fi
  echo
fi

# ── Summary ───────────────────────────────────────────────────────────────
if [ "$FAILED" -eq 0 ]; then
  echo "✓ ship-check passed — safe to push."
else
  echo "✗ ship-check FAILED — fix the ✗ gates above before pushing."
fi
exit "$FAILED"
