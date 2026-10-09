#!/usr/bin/env bash
# guard-git-secrets.sh: blocks staging secret-shaped paths, including through git -C / -c options,
# and blanket `git add -A/.` when $HOME is itself a repo (checked against a throwaway fake HOME).
here="$(cd "$(dirname "$0")" && pwd)"; hook="$here/../guard-git-secrets.sh"
mkdir -p "$here/fx"; fake="$(mktemp -d "$here/fx/gs.XXXXXX")"; git init -q "$fake"
pass=0; fail=0
case_() {  # case_ <block|allow> <command> [cwd]
  jq -cn --arg c "$2" --arg d "${3:-/tmp}" '{tool_name:"Bash",tool_input:{command:$c},cwd:$d}' | bash "$hook" >/dev/null 2>&1
  local rc=$? got=allow; [ $rc -eq 2 ] && got=block
  if [ "$got" = "$1" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL want=$1 got=$got :: $2"; fi
}
case_ block 'git add .env'
case_ block 'git add config/.env.production'
case_ block 'git -C /some/repo add .env'
case_ block 'git -c core.autocrlf=false add .env'
case_ block 'git -C ~/proj -c x=y add certs/server.key'
case_ block 'cd proj && git add id_ed25519'
HOME="$fake" case_ block 'git add -A' "$fake"
HOME="$fake" case_ block 'git -C ~ add .' /tmp
case_ allow 'git add .env.example'
case_ allow 'git add src/app.ts README.md'
case_ allow 'git -C /some/repo add src/a.ts'
case_ allow 'git commit -m "never git add .env"'
case_ allow 'git status'
echo "git-secrets: $pass passed, $fail failed"
[ $fail -eq 0 ]
