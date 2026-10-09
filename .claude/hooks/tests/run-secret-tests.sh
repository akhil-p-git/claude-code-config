#!/usr/bin/env bash
# secret-scan-git.sh against throwaway repos holding obviously fake credentials
# (assembled at runtime so no literal token sits in this file). Only git init/add/commit/
# push to a local bare repo; the hook itself is the only thing under test.
here="$(cd "$(dirname "$0")" && pwd)"; hook="$here/../secret-scan-git.sh"
mkdir -p "$here/fx"; root="$(mktemp -d "$here/fx/sec.XXXXXX")"; cd "$root" || exit 1
git init -q --bare remote.git
git init -q -b main repo; cd repo || exit 1
git config user.email t@example.com; git config user.name t
printf 'hello\n' > README.md; git add README.md; git commit -q -m init
git remote add origin "$root/remote.git"; git push -q -u origin main 2>/dev/null

a36="$(printf 'a%.0s' $(seq 36))"; GH="ghp_${a36}"
PK="-----BEGIN OPENSSH ""PRIVATE KEY-----"
pass=0; fail=0
run() {  # run <cmd> [cwd]
  jq -cn --arg c "$1" --arg cwd "${2:-$root/repo}" '{session_id:"t",cwd:$cwd,hook_event_name:"PreToolUse",tool_name:"Bash",tool_input:{command:$c}}' | "$hook"
}
expect() {  # expect <deny|none> <label> <output>
  local got; got="$(jq -r '.hookSpecificOutput.permissionDecision // empty' <<<"$3" 2>/dev/null)"; got="${got:-none}"
  if [ "$got" = "$1" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL [$2] want=$1 got=$got"; fi
}

printf 'export const token = "%s";\n' "$GH" > leak.ts; git add leak.ts
o="$(run 'git commit -m "add client"')"; expect deny "staged github token" "$o"
printf '%s' "$o" | jq -r .hookSpecificOutput.permissionDecisionReason | head -3
grep -q "$a36" <<<"$o" && { fail=$((fail+1)); echo "FAIL secret value echoed in reason"; }
git reset -q leak.ts; rm -f leak.ts

printf 'DATABASE_URL=postgres://user:password@localhost:5432/app\n' > example.env.txt; git add example.env.txt
o="$(run 'git commit -m docs')"; expect none "placeholder db url" "$o"
pw="Zq9x""K2mPw7"; printf 'DATABASE_URL=postgres://app:%s@db.example.com/app\n' "$pw" > example.env.txt; git add example.env.txt
o="$(run 'git commit -m docs')"; expect deny "db url with real-looking password" "$o"
git reset -q example.env.txt; rm -f example.env.txt

printf '%s\nb3BlbnNzaC1rZXktdjEAAAAA\n' "$PK" > id_test; git add id_test
o="$(run 'git add id_test && git commit -m key')"; expect deny "private key" "$o"
git reset -q id_test; rm -f id_test

printf 'const t = "%s"; // gitleaks:allow\n' "$GH" > allowed.ts; git add allowed.ts
o="$(run 'git commit -m fixture')"; expect none "gitleaks:allow honored" "$o"
git commit -q -m fixture

printf 'token=%s\n' "$GH" >> README.md
o="$(run 'git commit -m wip')"; expect none "unstaged change not included without -a" "$o"
o="$(run 'git commit -am wip')"; expect deny "commit -am includes tracked changes" "$o"
o="$(run "git -C $root/repo commit --all -m wip" /tmp)"; expect deny "git -C dir commit --all" "$o"
git checkout -q -- README.md

printf 'x=%s\n' "$GH" > cfg.txt; git add cfg.txt; git commit -q -m "oops"
o="$(run 'git push')"; expect deny "push scans unpushed commits" "$o"
o="$(run "cd $root/repo && git push origin main" /tmp)"; expect deny "cd dir && git push" "$o"
o="$(run 'git status')"; expect none "non-commit git command" "$o"
o="$(run 'npm test')"; expect none "non-git command" "$o"
o="$(run 'git log --grep commit')"; expect none "git log mentioning commit" "$o"
# `git add ...` in the same command hasn't run when PreToolUse fires: untracked files must be scanned too.
printf 'const t = "%s";\n' "$GH" > untracked.ts
o="$(run 'git add -A && git commit -m x')"; expect deny "git add -A && commit scans untracked files" "$o"
rm -f untracked.ts; printf 'nothing to see\n' > notes.txt
o="$(run 'git add -A && git commit -m x')"; expect none "git add -A && commit with clean untracked file" "$o"
rm -f notes.txt

# First publish: no upstream and no origin/HEAD, so every commit no remote has must be scanned.
git init -q --bare "$root/remote2.git"; git init -q -b main "$root/repo2"
git -C "$root/repo2" config user.email t@example.com; git -C "$root/repo2" config user.name t
printf 'k=%s\n' "$GH" > "$root/repo2/k.txt"; git -C "$root/repo2" add k.txt; git -C "$root/repo2" commit -q -m first
git -C "$root/repo2" remote add origin "$root/remote2.git"
o="$(run 'git push -u origin main' "$root/repo2")"; expect deny "first push with no upstream scans history" "$o"
git init -q -b main "$root/repo3"; git -C "$root/repo3" config user.email t@example.com; git -C "$root/repo3" config user.name t
printf 'clean\n' > "$root/repo3/a.txt"; git -C "$root/repo3" add a.txt; git -C "$root/repo3" commit -q -m first
git -C "$root/repo3" remote add origin "$root/remote2.git"
o="$(run 'git push -u origin main' "$root/repo3")"; expect none "first push of a clean history" "$o"

# Repo resolution follows every literal `cd` before the git segment; a non-literal one skips the scan.
printf 'export const token = "%s";\n' "$GH" > late.ts; git add late.ts
o="$(run "true; cd $root/repo && git commit -m x" /tmp)"; expect deny "non-leading literal cd is followed" "$o"
o="$(run 'r=$(mktemp -d); cd "$r" && git init -q && git commit -m x')"; expect none "non-literal cd target skips the scan" "$o"
# Heredoc bodies are data: a script that merely mentions a commit is not a commit...
o="$(run "$(printf 'python3 - <<%sEOF%s\nprint(\"git commit -m x\")\nEOF' "'" "'")")"; expect none "git commit inside a heredoc body is data" "$o"
# ...but a real commit whose message comes from a heredoc is still scanned.
o="$(run "$(printf 'git commit -F - <<%sEOF%s\nfix: thing\nEOF' "'" "'")")"; expect deny "commit with heredoc message still scanned" "$o"
git reset -q late.ts; rm -f late.ts

echo "secret-scan: $pass passed, $fail failed (scanner: $(command -v gitleaks >/dev/null && echo gitleaks || echo built-in))"
