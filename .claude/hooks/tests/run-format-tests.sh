#!/usr/bin/env bash
# Builds fake projects with stub formatters and checks format-on-edit.sh picks the right
# tool, passes only the edited file, stays silent on success, and reports failures.
here="$(cd "$(dirname "$0")" && pwd)"; hook="$here/../format-on-edit.sh"; stub="$here/fmt-stub.sh"
mkdir -p "$here/fx"; root="$(mktemp -d "$here/fx/fmt.XXXXXX")"; cd "$root" || exit 1
mkproj() {  # mkproj <dir> <formatter: prettier|biome|none>
  mkdir -p "$1/src" "$1/node_modules/.bin"
  case "$2" in
    prettier) printf '{"name":"p","devDependencies":{"prettier":"^3"}}\n' > "$1/package.json"; printf '{}\n' > "$1/.prettierrc"
              cp "$stub" "$1/node_modules/.bin/prettier" ;;
    biome)    printf '{"name":"b"}\n' > "$1/package.json"; printf '{}\n' > "$1/biome.json"
              cp "$stub" "$1/node_modules/.bin/biome"; cp "$stub" "$1/node_modules/.bin/prettier" ;;
    none)     printf '{"name":"n"}\n' > "$1/package.json" ;;
  esac
  : > "$1/calls.log"
}
mkproj p prettier; mkproj b biome; mkproj n none
mkdir -p py/.venv/bin py/pkg; printf '[project]\nname="x"\n' > py/pyproject.toml; cp "$stub" py/.venv/bin/ruff; : > py/calls.log
pass=0; fail=0
run() { jq -cn --arg fp "$1" '{session_id:"t",hook_event_name:"PostToolUse",tool_name:"Edit",tool_input:{file_path:$fp}}' | "$hook"; }
check() { if eval "$2"; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL: $1"; fi; }

printf 'const a = 1\n' > p/src/a.ts
o="$(run "$root/p/src/a.ts")"
check "prettier formats only the edited file" '[ -z "$o" ] && grep -q "formatted-by-prettier" p/src/a.ts && grep -q "prettier --write --log-level warn $root/p/src/a.ts$" p/calls.log'

printf 'const b = 2\n' > b/src/b.tsx
o="$(run "$root/b/src/b.tsx")"
check "biome preferred when biome.json exists" '[ -z "$o" ] && grep -q "formatted-by-biome" b/src/b.tsx && ! grep -q prettier b/calls.log'

printf 'const c = 3\n' > n/src/c.ts
o="$(run "$root/n/src/c.ts")"
check "no local formatter: untouched, silent" '[ -z "$o" ] && ! grep -q formatted n/src/c.ts'

printf 'const x = (\nSYNTAX_ERROR\n' > p/src/bad.ts
o="$(run "$root/p/src/bad.ts")"
check "syntax error reported as additionalContext" '[ "$(jq -r .hookSpecificOutput.hookEventName <<<"$o")" = PostToolUse ] && jq -r .hookSpecificOutput.additionalContext <<<"$o" | grep -q "SyntaxError"'

printf 'x=1\n' > py/pkg/m.py
o="$(run "$root/py/pkg/m.py")"
check "python uses project .venv ruff format" '[ -z "$o" ] && grep -q "ruff format --quiet $root/py/pkg/m.py" py/calls.log'

mkdir -p p/node_modules/dep; printf 'x\n' > p/node_modules/dep/i.js
o="$(run "$root/p/node_modules/dep/i.js")"
check "node_modules skipped" '[ -z "$o" ] && ! grep -q formatted p/node_modules/dep/i.js'

o="$(run "$root/p/src/missing.ts")"
check "deleted/missing file ignored" '[ -z "$o" ]'

# Monorepo: prettier hoisted to the workspace root; the edited package has no node_modules of its own.
mkdir -p mono/packages/web/src mono/node_modules/.bin; printf '{"name":"mono","devDependencies":{"prettier":"^3"}}\n' > mono/package.json
printf '{}\n' > mono/.prettierrc; cp "$stub" mono/node_modules/.bin/prettier; : > mono/calls.log
printf '{"name":"web"}\n' > mono/packages/web/package.json; printf 'const m = 1\n' > mono/packages/web/src/m.ts
o="$(run "$root/mono/packages/web/src/m.ts")"
check "monorepo: hoisted prettier found at the workspace root" '[ -z "$o" ] && grep -q "formatted-by-prettier" mono/packages/web/src/m.ts'

# Global formatters on PATH must not touch projects that don't pin them.
mkdir -p global/bin; cp "$stub" global/bin/ruff; cp "$stub" global/bin/shfmt; : > calls.log
mkdir -p blk/.venv/bin; printf '[project]\nname="b"\n[tool.black]\nline-length = 100\n' > blk/pyproject.toml; cp "$stub" blk/.venv/bin/black; : > blk/calls.log
printf 'y=2\n' > blk/m.py
o="$(PATH="$root/global/bin:$PATH" run "$root/blk/m.py")"
check "black project: black runs, global ruff does not" '[ -z "$o" ] && grep -q "formatted-by-black" blk/m.py && ! grep -q "formatted-by-ruff" blk/m.py'
mkdir -p plain; printf '[project]\nname="p"\n' > plain/pyproject.toml; printf 'z=3\n' > plain/m.py
o="$(PATH="$root/global/bin:$PATH" run "$root/plain/m.py")"
check "global ruff skipped when the project doesn't configure ruff" '[ -z "$o" ] && ! grep -q formatted plain/m.py'
printf '[tool.ruff]\nline-length = 100\n' >> plain/pyproject.toml
o="$(PATH="$root/global/bin:$PATH" run "$root/plain/m.py")"
check "global ruff used when [tool.ruff] is configured" '[ -z "$o" ] && grep -q "formatted-by-ruff" plain/m.py'
mkdir -p loose; printf 'w=4\n' > loose/s.py
o="$(PATH="$root/global/bin:$PATH" run "$root/loose/s.py")"
check "python file outside any project left alone" '[ -z "$o" ] && ! grep -q formatted loose/s.py'
mkdir -p sh1 sh2; printf 'echo  hi\n' > sh1/a.sh; printf 'echo  hi\n' > sh2/a.sh; printf 'root = true\n' > sh2/.editorconfig
o="$(PATH="$root/global/bin:$PATH" run "$root/sh1/a.sh")"
check "shfmt skipped without an .editorconfig" '[ -z "$o" ] && ! grep -q formatted sh1/a.sh'
o="$(PATH="$root/global/bin:$PATH" run "$root/sh2/a.sh")"
check "shfmt runs with an .editorconfig" '[ -z "$o" ] && grep -q "formatted-by-shfmt" sh2/a.sh'

t0=$(date +%s%N); for _ in $(seq 10); do run "$root/n/src/c.ts" >/dev/null; done; t1=$(date +%s%N)
echo "format-on-edit: $pass passed, $fail failed; overhead without a formatter: $(( (t1 - t0) / 10000000 )) ms/call"
