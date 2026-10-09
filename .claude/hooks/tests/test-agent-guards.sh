#!/usr/bin/env bash
# Test harness for readonly-bash-guard.sh and agent-write-guard.sh.
# Usage: bash test-guards.sh   (exit 0 = all pass; prints failures)
# Point at installed copies with BASH_GUARD=... WRITE_GUARD=... bash test-guards.sh
set -u
here=$(cd "$(dirname "$0")" && pwd)
bg="${BASH_GUARD:-$here/../readonly-bash-guard.sh}"
wg="${WRITE_GUARD:-$here/../agent-write-guard.sh}"
fail=0; n=0

bash_case() { # expect(allow|block) command
  local expect=$1 cmd=$2 json rc got
  json=$(jq -n --arg c "$cmd" '{tool_name:"Bash",tool_input:{command:$c},cwd:"/home/akhil/work/Dev/x"}')
  bash "$bg" <<<"$json" >/dev/null 2>&1; rc=$?
  if [ $rc -eq 0 ]; then got=allow; elif [ $rc -eq 2 ]; then got=block; else got="rc=$rc"; fi
  n=$((n+1))
  if [ "$got" != "$expect" ]; then fail=$((fail+1)); printf 'FAIL bash  expect=%-5s got=%-5s  %q\n' "$expect" "$got" "$cmd"; fi
}

write_case() { # expect agent path
  local expect=$1 agent=$2 path=$3 json rc got
  json=$(jq -n --arg p "$path" '{tool_name:"Write",tool_input:{file_path:$p,content:"x"},cwd:"/home/akhil/work/Dev/proj"}')
  bash "$wg" "$agent" <<<"$json" >/dev/null 2>&1; rc=$?
  if [ $rc -eq 0 ]; then got=allow; elif [ $rc -eq 2 ]; then got=block; else got="rc=$rc"; fi
  n=$((n+1))
  if [ "$got" != "$expect" ]; then fail=$((fail+1)); printf 'FAIL write expect=%-5s got=%-5s  %s %s\n' "$expect" "$got" "$agent" "$path"; fi
}

# ---------- read-only work the agents rely on: must be allowed
bash_case allow 'git diff HEAD'
bash_case allow 'git -C /repo log --oneline -5'
bash_case allow 'git --no-pager log -p -- src/a.ts'
bash_case allow 'git -c core.pager=cat diff --stat'
bash_case allow 'git show HEAD~1:src/app.ts'
bash_case allow 'git blame -L 10,20 src/a.ts'
bash_case allow 'git status --porcelain'
bash_case allow 'git stash list'
bash_case allow 'git stash show -p stash@{0}'
bash_case allow 'git branch --show-current'
bash_case allow 'git branch -a'
bash_case allow 'git branch --contains abc123'
bash_case allow 'git tag --list'
bash_case allow 'git config --get user.name'
bash_case allow 'git worktree list'
bash_case allow 'git fetch origin'
bash_case allow 'git log --format= --name-only | sort | uniq -c | sort -rn | head -20'
bash_case allow 'gh pr diff 12'
bash_case allow 'gh pr view 12 --comments'
bash_case allow 'gh run view 123 --log-failed'
bash_case allow 'gh api repos/vercel/next.js/releases/latest --jq .tag_name'
bash_case allow 'grep -rn "rm -rf" src 2>/dev/null'
bash_case allow 'grep -rn npx .github/'
bash_case allow 'rg wget docs'
bash_case allow "rg 'x => y' src"
bash_case allow "jq '.items[] | select(.n > 1)' data.json"
bash_case allow "awk '\$3 > 100' file.txt"
bash_case allow 'python3 -c "print(1 > 0)"'
bash_case allow 'npx --no -- tsc --noEmit 2>&1 | tail -20'
bash_case allow 'pnpm exec tsc --noEmit'
bash_case allow './node_modules/.bin/tsc --noEmit'
bash_case allow 'npm test -- src/a.test.ts'
bash_case allow 'npm audit --json > /tmp/audit.json'
bash_case allow 'npm audit --json > "/tmp/audit.json"'
bash_case allow 'npm audit --omit=dev --json'
bash_case allow 'pnpm audit --prod'
bash_case allow 'npm view left-pad time.created maintainers repository scripts --json'
bash_case allow 'npm ls --all 2>&1 | head -50'
bash_case allow 'uv lock --check'
bash_case allow 'npm install --dry-run'
bash_case allow 'uv run --frozen pytest -q'
bash_case allow 'uv run --no-project --with numpy python3 /tmp/x.py'
bash_case allow 'uv run --frozen --with numpy python3 ~/.claude/skills/finance/scripts/bt_report.py /tmp/returns.csv'
bash_case allow 'uv export --frozen --format requirements.txt --no-hashes > /tmp/reqs.txt'
bash_case allow 'find . -name "*.ts" -not -path "*/node_modules/*"'
bash_case allow 'ls -la && cat package.json | head -40'
bash_case allow 'echo done > /dev/null'
bash_case allow 'some_cmd &>/dev/null'
bash_case allow 'echo oops >&2'
bash_case allow $'cat > /tmp/check.py <<\'EOF\'\nimport sys\nif len(sys.argv) > 1: print("x")\nEOF\npython3 /tmp/check.py a'
bash_case allow $'python3 - <<\'EOF\'\nimport os\nos.remove("x") if False else None\nEOF'
bash_case allow 'duckdb -c "select count(*) from read_parquet(\"data/*.parquet\")"'
bash_case allow $'duckdb -c "\nSELECT symbol, sum(pnl)\nFROM trades\nWHERE pnl > 0\nGROUP BY 1"'
bash_case allow 'psql "$DATABASE_URL" -c "select * from orders where created_at >= now() - interval \"1 day\""'
bash_case allow 'duckdb -c "CREATE TEMP TABLE t AS SELECT 1; SELECT * FROM t"'
bash_case allow 'psql -c "\copy (select 1) to /tmp/x.csv csv"'
bash_case allow 'mkdir -p /tmp/review && cp src/a.ts /tmp/review/'
bash_case allow 'rm -f /tmp/x.log'
bash_case allow 'npm test 2>&1 | tee /tmp/test.log | tail -5'
bash_case allow 'chmod +x /tmp/run.sh'
bash_case allow 'node --cpu-prof --cpu-prof-dir=/tmp/prof script.js'
bash_case allow 'npm run dev > /tmp/dev.log 2>&1 &'
bash_case allow 'curl -s http://localhost:3000/api/health | jq .'
bash_case allow 'curl -sS -o /tmp/page.html https://example.com'
bash_case allow 'wget -qO- https://example.com'
bash_case allow 'docker ps && docker logs api --tail 50'
bash_case allow 'prettier --check .'
bash_case allow 'ruff format --check .'
bash_case allow 'black --diff src'
bash_case allow 'timeout 60 npx --no -- vitest run src/a.test.ts'
bash_case allow 'kill $(cat /tmp/dev.pid)'
bash_case allow 'export FOO=1 && psql -c "select 1"'
bash_case allow 'PGPASSWORD=x psql -h localhost -c "select count(*) from orders" && echo drop'
bash_case allow 'git log -S reset --oneline'
bash_case allow 'grep -rn "DELETE" src'

# ---------- state-changing commands: must be blocked
bash_case block 'rm -rf node_modules'
bash_case block 'git checkout main'
bash_case block 'git checkout -- src/a.ts'
bash_case block 'git stash'
bash_case block 'git stash pop'
bash_case block 'git stash -u'
bash_case block 'git stash && git checkout main'
bash_case block 'git reset --hard HEAD~1'
bash_case block "git -C '/repo' reset --hard HEAD~1"
bash_case block 'git -C "$(git rev-parse --show-toplevel)" stash'
bash_case block 'git --no-pager -c x=y checkout main'
bash_case block 'git commit -m "wip"'
bash_case block 'git push origin main'
bash_case block 'git add -A'
bash_case block 'git -C /repo switch -c tmp'
bash_case block 'git branch -D feature'
bash_case block 'git branch tmp-review'
bash_case block 'git bisect start HEAD v1.0'
bash_case block 'git worktree add /tmp/wt HEAD'
bash_case block 'git tag v1.0.0'
bash_case block 'git config user.email x@y.z'
bash_case block 'echo $(git stash)'
bash_case block 'gh pr checkout 12'
bash_case block 'gh pr comment 12 --body hi'
bash_case block 'gh api -X POST repos/o/r/issues -f title=x'
bash_case block 'npm install lodash'
bash_case block 'pnpm add zod'
bash_case block 'yarn'
bash_case block 'pip install requests'
bash_case block 'uv add httpx'
bash_case block 'uv lock'
bash_case block 'uv lock --check || uv lock'
bash_case block 'uv run python x.py'
bash_case block 'uv tool install ruff'
bash_case block 'npm publish'
bash_case block 'npm version patch'
bash_case block 'npx knip'
bash_case block 'npx tsc --noEmit'
bash_case block 'pnpm dlx create-next-app x'
bash_case block 'npx playwright install chromium'
bash_case block 'pnpm exec playwright install chromium'
bash_case block 'install -m 755 a /usr/local/bin/a'
bash_case block "sed -i 's/a/b/' src/a.ts"
bash_case block "sed -E -i 's/a/b/' src/a.ts"
bash_case block "perl -pi -e 's/a/b/' src/a.ts"
bash_case block 'echo x > src/file.ts'
bash_case block 'cat a.txt >> b.txt'
bash_case block 'git diff | tee out.patch'
bash_case block 'mv a.ts b.ts'
bash_case block 'mv src/a.ts /tmp/'
bash_case block 'mkdir newdir'
bash_case block 'touch src/new.ts'
bash_case block 'chmod +x scripts/run.sh'
bash_case block '\rm -rf build'
bash_case block '/bin/rm -rf build'
bash_case block 'time rm -rf build'
bash_case block 'FOO=1 rm -rf build'
bash_case block 'xargs rm < list.txt'
bash_case block 'xargs -I {} cp {} src/'
bash_case block 'npx --no -- eslint . --fix'
bash_case block 'npx --no -- prettier --write .'
bash_case block 'npx --no -- prettier -w src'
bash_case block 'ruff format .'
bash_case block 'black src/'
bash_case block 'npm audit fix'
bash_case block 'find . -name "*.log" -delete'
bash_case block 'find . -name "*.tmp" -exec rm {} \;'
bash_case block 'find . \( -name "*.log" -o -name "*.tmp" \) -delete'
bash_case block 'ls; rm file'
bash_case block $'cat > /tmp/x.txt <<\'X\'\nhello\nX\ngit stash && git checkout main'
bash_case block $'cat > src/gen.ts <<\'EOF\'\nexport const x = 1\nEOF'
bash_case block 'duckdb data.duckdb -c "CREATE TABLE x AS SELECT 1"'
bash_case block 'psql "$DATABASE_URL" -c "delete from users where id = 1"'
bash_case block $'psql "$DATABASE_URL" <<\'SQL\'\nUPDATE users SET plan = \'pro\';\nSQL'
bash_case block 'sqlite3 app.db "drop table sessions"'
bash_case block 'curl -X POST https://api.example.com/x -d "{}"'
bash_case block 'curl -O https://example.com/file.tgz'
bash_case block 'wget https://example.com/file.tgz'
bash_case block 'docker compose up -d'
bash_case block 'sudo pacman -Syu'
bash_case block 'psql -c "select 1; drop table x"'
bash_case block 'PGPASSWORD=x psql -c "insert into t values (1)"'

# ---------- carried over from the previous suite (npx without --no now blocks: it can download an unrelated package)
bash_case block 'npx tsc --noEmit 2>&1 | tail -20'
bash_case allow 'pip-audit -f json'
bash_case allow 'npm view left-pad time --json'
bash_case allow $'cat > /tmp/check.py <<\'EOF\'\nimport sys\nif len(sys.argv) > 1: print("x")\nEOF'
bash_case allow 'grep -rn "npm install" README.md'
bash_case block 'npx eslint . --fix'
bash_case block 'npx prettier --write .'
bash_case allow 'npx --no -- tsc --noEmit 2>&1 | tail -20'

# ---------- fresh-context review cases, verbatim forms (2026-10-08)
bash_case block 'npx prettier -w .'
bash_case block 'npm exec -- playwright install chromium'
bash_case allow 'mkdir -p /tmp/x'
bash_case allow 'cp f /tmp/'
bash_case allow 'some_cmd | tee /tmp/x'
# uv: lockfile-respecting forms are allowed, anything that may rewrite uv.lock is not
bash_case block 'uv sync'
bash_case allow 'uv sync --locked'
bash_case allow 'uv sync --frozen'
bash_case allow 'uv sync --dry-run'
bash_case allow 'uv run --locked pytest -q'
bash_case block 'uv run --offline python x.py'
bash_case block 'uv run --no-sync python x.py'

# ---------- write guard (memory agents)
write_case allow code-reviewer "$HOME/.claude/agent-memory/code-reviewer/MEMORY.md"
write_case allow code-reviewer "$HOME/.claude/agent-memory/code-reviewer/project_x.md"
write_case allow code-reviewer "/home/akhil/work/Dev/proj/.claude/agent-memory/code-reviewer/notes.md"
write_case allow code-reviewer "/home/akhil/work/Dev/proj/.claude/agent-memory-local/code-reviewer/notes.md"
write_case allow code-reviewer "/tmp/review-scratch.py"
write_case block code-reviewer "$HOME/.claude/agent-memory/architect/MEMORY.md"
write_case block code-reviewer "$HOME/.claude/agent-memory/code-reviewer/../../settings.json"
write_case block code-reviewer "/home/akhil/work/Dev/proj/src/index.ts"
write_case block code-reviewer "src/index.ts"
write_case block code-reviewer "/tmpevil/x"
write_case block ""            "/tmp/x"

echo "$((n-fail))/$n passed"
[ $fail -eq 0 ]
