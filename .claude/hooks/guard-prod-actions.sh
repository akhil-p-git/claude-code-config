#!/usr/bin/env bash
# PreToolUse(Bash) guard for production-affecting and irreversible commands.
#   deny (exit 2)  — irreversible data/infra loss the agent must never run itself; the user runs it
#                    with `! <command>` after reading the plan. Examples: terraform/tofu destroy or
#                    -auto-approve, drizzle-kit push --force, prisma migrate reset / --accept-data-loss /
#                    --force-reset, supabase db reset --linked, kubectl delete namespace|--all,
#                    fly apps|volumes destroy, wrangler delete, gh repo delete, DROP DATABASE.
#   ask (JSON)     — production deploys, promotions, rollbacks, publishes, releases, infra apply,
#                    remote migrations, platform secret changes, image pushes, volume-deleting docker
#                    commands, mutating `gh` calls, and git pushes (except plain pushes in this config repo).
#   silent exit 0  — everything else goes through the normal permission flow.
# Why a hook: CLAUDE.md prose and `allow` rules like Bash(gh:*) / Bash(npm:*) / Bash(docker:*) let these
# run unprompted, and agent incidents in 2025-26 (drizzle-kit push --force, terraform destroy) came from
# exactly these commands. A hook "ask" also forces a prompt in auto mode.
# Matching: quoted strings are dropped (commit messages, grep patterns), `sh -c '…'` payloads are
# checked, each segment is matched at command position after stripping VAR=val prefixes and wrappers
# (sudo, env, time, timeout, nice, nohup, npx, pnpm exec/dlx, bunx, uvx, uv run, dotenv/doppler/op/
# infisical run --). It is a slip-catcher, not a sandbox. Fails open on parse errors; keep it fast
# (a timed-out hook does not block).
set -uo pipefail

ask_raw() { # emit an "ask" decision without jq (used when the input can't be inspected)
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"guard-prod-actions: %s"}}\n' "$1"
  exit 0
}
input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || ask_raw "jq is missing, so this command could not be safety-checked. Approve only if you know what it does."
cmd=$(jq -r '.tool_input.command // empty' <<<"$input" 2>/dev/null) || ask_raw "could not parse the tool input to safety-check this command. Approve only if you know what it does."
[ -z "$cmd" ] && exit 0
# Obfuscated commands can't be inspected; make a human read them.
if grep -Eq 'base64[[:space:]]+(-d|--decode)[^|]*\|[[:space:]]*(ba|z)?sh|\$\{?IFS|(^|[;&|[:space:]])eval[[:space:]]' <<<"$cmd"; then
  ask_raw "obfuscated shell (base64-to-shell, \$IFS, or eval) cannot be inspected. Read it before approving."
fi
# Fast path: a command naming none of the programs, verbs, or script words the rules below match
# can't trigger any of them, so skip the per-segment analysis (~5 ms instead of 100-250 ms).
# Verbs match as bare substrings so script names like predeploy.sh or deploy_prod.sh still get checked.
fast_prog='(^|[^A-Za-z0-9_-])(terraform|tofu|terragrunt|pulumi|drizzle-kit|prisma|supabase|kubectl|helm|argocd|flux|fly|flyctl|wrangler|railway|netlify|heroku|vercel|vc|docker|docker-compose|gh|twine|poetry|hatch|flit|cargo|gem|changeset|semantic-release|atlas|alembic|aws|gcloud|az|doctl|hcloud|psql|pgcli|mysql|mariadb|sqlite3|duckdb|clickhouse|turso|neonctl|push|unpublish|deprecate|dist-tag|execute)([^A-Za-z0-9_-]|$)'
fast_word='deploy|release|publish|ship|promote|rollback|db:|migrate:'
shopt -s nocasematch
[[ $cmd =~ $fast_prog || $cmd =~ $fast_word ]] || exit 0
shopt -u nocasematch
cwd=$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null)
config_repo="$HOME/dev/claude-code-config"

raw=$cmd
# Heredoc bodies are data unless fed to a shell.
if grep -q '<<' <<<"$cmd" && ! head -n1 <<<"$cmd" | grep -Eq '(^|[;&|[:space:]])(ba|z)?sh[[:space:]]*<<'; then
  cmd=$(head -n1 <<<"$cmd")
fi
# Payloads of `sh -c '…'` / `bash -c "…"` are commands: append them as extra lines.
payloads=$(grep -oE "(ba|z)?sh[[:space:]]+-[a-z]*c[[:space:]]+('[^']*'|\"[^\"]*\")" <<<"$cmd" \
  | sed -E "s/^(ba|z)?sh[[:space:]]+-[a-z]*c[[:space:]]+//; s/^'(.*)'\$/\1/; s/^\"(.*)\"\$/\1/")
s=$(printf '%s\n%s' "$cmd" "$payloads" | sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g")
# Drop fd duplication and &> redirects so `&` only means a separator; then split into segments.
s=$(sed -E 's/[0-9]*>&[0-9-]+//g; s/&>>?/>/g' <<<"$s" | sed -E 's/&&|\|\||;|\||&|\(|\)|`/\n/g')

strip_prefixes() { # remove VAR=val assignments and process wrappers until stable
  local seg=$1 prev=""
  while [ "$seg" != "$prev" ]; do
    prev=$seg
    seg=$(sed -E \
      -e 's/^[[:space:]]+//' \
      -e 's/^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+//' \
      -e 's/^(sudo|doas)([[:space:]]+-[A-Za-z]+)*[[:space:]]+//' \
      -e 's/^env([[:space:]]+-[A-Za-z]+)*[[:space:]]+//' \
      -e 's/^(command|exec|nohup|time([[:space:]]+-p)?)[[:space:]]+//' \
      -e 's/^nice([[:space:]]+-n[[:space:]]*-?[0-9]+)?[[:space:]]+//' \
      -e 's/^timeout([[:space:]]+-[A-Za-z-]+([[:space:]]+[0-9A-Za-z]+)?)*[[:space:]]+[0-9.]+[smhd]?[[:space:]]+//' \
      -e 's/^npx([[:space:]]+(--yes|-y|--no-install|--package[= ][^[:space:]]+|-p[[:space:]]+[^[:space:]]+))*[[:space:]]+//' \
      -e 's/^(pnpm|yarn)[[:space:]]+(exec|dlx)[[:space:]]+//' \
      -e 's/^(bunx|uvx)[[:space:]]+//' -e 's/^bun[[:space:]]+x[[:space:]]+//' \
      -e 's/^npm[[:space:]]+(exec|x)([[:space:]]+(--yes|-y|--package[= ][^[:space:]]+))*([[:space:]]+--)?[[:space:]]+//' \
      -e 's/^xargs([[:space:]]+(-[IinLPsE][[:space:]]*[^[:space:]]+|-[^[:space:]]+))*[[:space:]]+//' \
      -e 's/^(pnpm|yarn|bun)[[:space:]]+(vercel|vc|wrangler|fly|flyctl|netlify|railway|terraform|tofu|prisma|drizzle-kit|supabase|semantic-release|changeset|kubectl|helm)([[:space:]]|$)/\2\3/' \
      -e 's/^([A-Za-z][A-Za-z0-9._-]*)@[^[:space:]]+/\1/' \
      -e 's/^uv[[:space:]]+run([[:space:]]+--[a-z-]+)*[[:space:]]+//' \
      -e 's/^(dotenv|doppler[[:space:]]+run|op[[:space:]]+run|infisical[[:space:]]+run)([[:space:]]+[^[:space:]]+)*[[:space:]]+--[[:space:]]+//' \
      -e 's#^[^[:space:]]*/([A-Za-z0-9._-]+)#\1#' \
      <<<"$seg")
  done
  printf '%s' "$seg"
}

# Optional global flags between a program and its subcommand (`kubectl --context x -n y apply`,
# `terraform -chdir=infra apply`, `pnpm -r publish`); rules write it as @O@.
OPTS='([[:space:]]+-{1,2}[A-Za-z][A-Za-z0-9-]*(=[^[:space:]]+)?([[:space:]]+[^-[:space:]][^[:space:]]*)?)*'
# Rules: LEVEL <TAB> ERE matched against the normalized segment <TAB> reason. Deny rules first.
rules=$(cat <<'RULES'
deny	^(terraform|tofu|terragrunt)[[:space:]].*-auto-approve	-auto-approve skips the plan review; save a plan, show it, and let the user apply it
deny	^(terraform|tofu|terragrunt)[[:space:]](.*[[:space:]])?destroy([[:space:]]|$)	terraform destroy deletes real infrastructure
deny	^(terraform|tofu|terragrunt)[[:space:]].*apply[[:space:]].*-destroy	apply -destroy deletes real infrastructure
deny	^pulumi[[:space:]]+destroy	pulumi destroy deletes real infrastructure
deny	^drizzle-kit[[:space:]]+push[[:space:]].*--force	drizzle-kit push --force auto-accepts data-loss statements
deny	^prisma[[:space:]]+migrate[[:space:]]+reset	prisma migrate reset drops the database
deny	^prisma[[:space:]].*(--accept-data-loss|--force-reset)	this flag accepts data loss without a prompt
deny	^supabase[[:space:]]+db[[:space:]]+reset[[:space:]].*(--linked|--db-url)	resets a remote database
deny	^kubectl@O@[[:space:]]+delete[[:space:]]+(namespace|namespaces|ns)([[:space:]]|/)	deletes a whole namespace
deny	^kubectl[[:space:]]+delete[[:space:]].*--all([[:space:]]|$)	deletes every matching resource
deny	^(fly|flyctl)@O@[[:space:]]+(apps|volumes?|vol|postgres|pg)[[:space:]]+(destroy|delete|rm)	deletes a Fly app or volume
deny	^wrangler[[:space:]]+(delete|d1[[:space:]]+delete|r2[[:space:]]+bucket[[:space:]]+delete|kv[[:space:]]+namespace[[:space:]]+delete|queues[[:space:]]+delete)	deletes a Cloudflare resource
deny	^gh[[:space:]]+repo[[:space:]]+delete	deletes a GitHub repository
deny	^railway[[:space:]]+delete	deletes a Railway project
deny	^heroku[[:space:]]+(apps:destroy|pg:reset)	deletes a Heroku app or database
ask	^(vercel|vc)([[:space:]].*)?[[:space:]](--prod|--production|--target[= ]production)([[:space:]]|$)	production deploy on Vercel
ask	^(vercel|vc)@O@[[:space:]]+(promote|rollback|rolling-release|alias|domains|dns|certs|redeploy|remove|rm)([[:space:]]|$)	changes what production serves on Vercel
ask	^(vercel|vc)@O@[[:space:]]+env[[:space:]]+(add|rm|remove|update)	changes Vercel environment variables (applies to the next deploy)
ask	^(fly|flyctl)@O@[[:space:]]+(deploy|scale|secrets[[:space:]]+(set|unset|import)|machines?[[:space:]]+(destroy|stop|restart|update|clone)|m[[:space:]]+(destroy|stop|update)|ips[[:space:]]+release|certs[[:space:]]+(remove|delete))	changes a running Fly app
ask	^wrangler@O@[[:space:]]+(deploy|publish|rollback|versions[[:space:]]+deploy|triggers[[:space:]]+deploy|pages[[:space:]]+deploy|secret[[:space:]]+(put|delete|bulk))	production deploy or secret change on Cloudflare
ask	^wrangler[[:space:]].*--remote	touches remote Cloudflare data
ask	^railway@O@[[:space:]]+(up|redeploy|down|variables[[:space:]].*(--set|-s[[:space:]]))	deploy or variable change on Railway
ask	^netlify[[:space:]]+deploy[[:space:]].*--prod	production deploy on Netlify
ask	^heroku[[:space:]]+(releases:rollback|config:(set|unset)|ps:scale|container:release)	changes a running Heroku app
ask	^(terraform|tofu|terragrunt)@O@[[:space:]]+(apply|import|taint|untaint|force-unlock|state[[:space:]]+(rm|mv|push|replace-provider)|run-all[[:space:]]+apply|workspace[[:space:]]+delete)	changes infrastructure or state
ask	^pulumi@O@[[:space:]]+(up|refresh|import|state[[:space:]]+(delete|unprotect|move)|stack[[:space:]]+rm)	changes infrastructure or state
ask	^kubectl@O@[[:space:]]+(apply|create|replace|patch|edit|delete|scale|drain|cordon|uncordon|taint|annotate|label|set|autoscale|expose|rollout[[:space:]]+(undo|restart|pause|resume))	changes a Kubernetes cluster
ask	^helm@O@[[:space:]]+(install|upgrade|uninstall|delete|rollback)	changes a Helm release
ask	^(argocd[[:space:]]+app[[:space:]]+(sync|delete|rollback)|flux[[:space:]]+(reconcile|suspend|resume|delete))	changes a GitOps-managed cluster
ask	^docker([[:space:]]+image)?[[:space:]]+push	pushes an image to a registry
ask	^docker[[:space:]]+(buildx[[:space:]]+)?build[[:space:]].*--push	pushes an image to a registry
ask	^docker[[:space:]]+compose[[:space:]].*(down|rm)[[:space:]].*(-v|--volumes)([[:space:]]|$)	deletes compose volumes (database data)
ask	^docker-compose[[:space:]].*(down|rm)[[:space:]].*(-v|--volumes)([[:space:]]|$)	deletes compose volumes (database data)
ask	^docker[[:space:]]+(volume[[:space:]]+(rm|prune)|system[[:space:]]+prune[[:space:]].*--volumes)	deletes Docker volumes (database data)
ask	^(npm|pnpm|bun)@O@[[:space:]]+(publish|unpublish|deprecate|dist-tag[[:space:]]+(add|rm))	publishes to the npm registry
ask	^yarn[[:space:]]+(npm[[:space:]]+)?publish	publishes to the npm registry
ask	^(uv[[:space:]]+publish|twine[[:space:]]+upload|poetry[[:space:]]+publish|hatch[[:space:]]+publish|flit[[:space:]]+publish|cargo[[:space:]]+publish|gem[[:space:]]+push|changeset[[:space:]]+publish|semantic-release)	publishes a package or release
ask	^gh[[:space:]]+(release[[:space:]]+(create|edit|delete|upload|delete-asset)|workflow[[:space:]]+(run|enable|disable)|run[[:space:]]+(rerun|cancel)|secret[[:space:]]+(set|delete|remove)|variable[[:space:]]+(set|delete)|repo[[:space:]]+(archive|rename|edit|transfer)|pr[[:space:]]+merge)	outward-facing GitHub change (release, workflow, secret, merge)
ask	^gh[[:space:]]+api[[:space:]].*(-X|--method)[= ]?(POST|PUT|PATCH|DELETE|post|put|patch|delete)	mutating GitHub API call
ask	^(npm|pnpm|yarn|bun)[[:space:]]+((run|run-script)[[:space:]]+)?(deploy|release|publish|ship|promote|rollback|db:(push|reset|drop|deploy|migrate:prod)|migrate:(prod|deploy))([:[:space:]]|$)	package script that may deploy, publish, or migrate (check what it runs)
ask	^((ba|z)?sh[[:space:]]+|node[[:space:]]+|python3?[[:space:]]+|tsx[[:space:]]+|bun[[:space:]]+)?[^[:space:]]*(deploy|release|publish|rollback|promote)[^[:space:]]*\.(sh|bash|py|ts|js|mjs|cjs)([[:space:]]|$)	script that may deploy or publish (check what it runs)
ask	^drizzle-kit[[:space:]]+push	drizzle-kit push applies schema changes with no migration file to review
ask	^prisma[[:space:]]+(migrate[[:space:]]+deploy|db[[:space:]]+(push|update|migrate)|migrate[[:space:]]+resolve)	applies migrations or schema changes to the configured database
ask	^prisma[[:space:]].*--shadow-database-url	the shadow database is reset by design; make sure it is not a real database
ask	^supabase@O@[[:space:]]+(db[[:space:]]+push|migration[[:space:]]+(repair|squash|up)|secrets[[:space:]]+(set|unset)|functions[[:space:]]+(deploy|delete)|link|branches[[:space:]]+delete)	changes a remote Supabase project
ask	^atlas[[:space:]]+(schema|migrate)[[:space:]]+apply	applies schema changes
ask	^alembic@O@[[:space:]]+downgrade	migration downgrades usually drop tables or columns
ask	^(aws|gcloud|az|doctl|hcloud)[[:space:]].*(delete|terminate|destroy|remove|purge|[[:space:]]rm([[:space:]]|$)|[[:space:]]rb([[:space:]]|$))	deletes cloud resources
RULES
)

deny_reasons=(); ask_reasons=()
while IFS= read -r seg; do
  [ -z "${seg//[[:space:]]/}" ] && continue
  norm=$(strip_prefixes "$seg")
  # Track `cd` so `cd <config repo> && git push` resolves the right repo (unquoted paths only).
  if [[ $norm =~ ^cd[[:space:]]+([^[:space:]]+)[[:space:]]*$ ]]; then
    d=${BASH_REMATCH[1]}; d=${d/#\~/$HOME}; d=${d/#\$HOME/$HOME}
    case $d in /*) cwd=$d ;; *) cwd=${cwd:-$PWD}/$d ;; esac
    continue
  fi
  # Dry runs, plans, and local-only Vercel commands (build/pull with prod env) are always fine.
  grep -Eq -- '--dry-run|--explain|(^|[[:space:]])--show([[:space:]]|$)|(^|[[:space:]])(plan|diff|template|lint)([[:space:]]|$)' <<<"$norm" \
    && ! grep -Eq -- '-auto-approve|(^|[[:space:]])destroy([[:space:]]|$)' <<<"$norm" && continue
  grep -Eq '^(vercel|vc)[[:space:]]+(build|pull|inspect|logs|ls|list|env[[:space:]]+(ls|pull))([[:space:]]|$)' <<<"$norm" && continue
  while IFS=$'\t' read -r level re reason; do
    [ -z "$level" ] && continue
    re=${re//@O@/$OPTS}
    if grep -Eq -- "$re" <<<"$norm"; then
      if [ "$level" = deny ]; then deny_reasons+=("$reason: \`$norm\`"); else ask_reasons+=("$reason: \`$norm\`"); fi
      break
    fi
  done <<<"$rules"
  # git push: ask, except a plain (non-force, non-tag, non-delete) push from the config repo.
  if grep -Eq '^git([[:space:]]+-[Cc][[:space:]]+[^[:space:]]+)*[[:space:]]+push([[:space:]]|$)' <<<"$norm"; then
    dir=${cwd:-$PWD}
    c_arg=$(grep -oE -- '-C[[:space:]]+[^[:space:]]+' <<<"${norm%%push*}" | tail -n1 | sed -E 's/^-C[[:space:]]+//')
    if [ -n "$c_arg" ]; then
      c_arg=${c_arg/#\~/$HOME}; c_arg=${c_arg/#\$HOME/$HOME}
      case $c_arg in /*) dir=$c_arg ;; *) dir=$dir/$c_arg ;; esac
    fi
    top=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || true)
    if grep -Eq -- '(^|[[:space:]])(-f|--force|--force-with-lease[^[:space:]]*|--mirror|--delete|-d|--tags|--follow-tags)([[:space:]]|$)|[[:space:]]\+[^[:space:]]+|[[:space:]]:[^[:space:]]+' <<<"$norm"; then
      ask_reasons+=("force/tag/delete push rewrites or publishes shared refs: \`$norm\`")
    elif [ "$top" != "$config_repo" ]; then
      ask_reasons+=("push publishes commits (and may trigger a deploy): \`$norm\`")
    fi
  fi
done <<<"$s"

# SQL that drops or truncates data, wherever it appears (quoted SQL included).
if grep -Eiq '(psql|pgcli|mysql|mariadb|sqlite3|duckdb|clickhouse|turso|neonctl|d1[[:space:]]+execute|db[[:space:]]+execute)' <<<"$raw"; then
  if grep -Eiq 'drop[[:space:]]+database' <<<"$raw"; then
    deny_reasons+=("DROP DATABASE")
  elif grep -Eiq '(drop[[:space:]]+(table|schema|index|view)|truncate[[:space:]]|delete[[:space:]]+from[[:space:]]+[^[:space:];]+[[:space:]]*($|;|"|'"'"'))' <<<"$raw"; then
    ask_reasons+=("destructive SQL (DROP/TRUNCATE/DELETE without WHERE)")
  fi
fi

if [ ${#deny_reasons[@]} -gt 0 ]; then
  printf 'Blocked by guard-prod-actions: %s. This is irreversible: show the user the exact command, the plan or diff, and the backup/rollback state, and let them run it themselves with `! <command>`.\n' "$(IFS='; '; echo "${deny_reasons[*]}")" >&2
  exit 2
fi
if [ ${#ask_reasons[@]} -gt 0 ]; then
  reason="guard-prod-actions: $(IFS='; '; echo "${ask_reasons[*]}"). Confirm the target environment, the checks that passed, and the rollback path before approving."
  jq -n --arg r "$reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'
fi
exit 0
