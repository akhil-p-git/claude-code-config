#!/usr/bin/env bash
# Test harness for guard-prod-actions.sh.
# Usage: bash .claude/hooks/tests/test-guard-prod-actions.sh  (exit 0 = all pass)
set -u
here=$(cd "$(dirname "$0")" && pwd)
g="$here/../guard-prod-actions.sh"
fail=0; n=0

case_() { # expect(allow|ask|deny) command [cwd]
  local expect=$1 cmd=$2 cwd=${3:-/home/akhil/work/Dev/x} json out rc got
  json=$(jq -n --arg c "$cmd" --arg d "$cwd" '{tool_name:"Bash",tool_input:{command:$c},cwd:$d}')
  out=$(bash "$g" <<<"$json" 2>/dev/null); rc=$?
  if [ $rc -eq 2 ]; then got=deny
  elif [ $rc -eq 0 ] && [ -n "$out" ] && [ "$(jq -r '.hookSpecificOutput.permissionDecision' <<<"$out")" = ask ]; then got=ask
  elif [ $rc -eq 0 ]; then got=allow
  else got="rc=$rc"; fi
  n=$((n+1))
  if [ "$got" != "$expect" ]; then fail=$((fail+1)); printf 'FAIL expect=%-5s got=%-5s  %s\n' "$expect" "$got" "$cmd"; fi
}

# --- config-repo push exemption via cd / -C (added on install)
case_ allow 'git push' /home/akhil/dev/claude-code-config
case_ allow 'git -C ~/dev/claude-code-config push' /home/akhil
case_ allow 'git -C /home/akhil/dev/claude-code-config push origin master' /home/akhil
case_ allow 'cd ~/dev/claude-code-config && git push' /home/akhil
case_ allow 'cd ~/dev/claude-code-config && git add -A && git commit -q -F /tmp/m.txt && git push 2>&1 | tail -3' /home/akhil
case_ ask   'cd ~/dev/claude-code-config && git push --force' /home/akhil
case_ ask   'git -C ~/dev/claude-code-config push --tags' /home/akhil
case_ ask   'cd ~/work/Dev/x && git push' /home/akhil/dev/claude-code-config
case_ ask   'git -C /tmp push' /home/akhil/dev/claude-code-config
case_ ask   'cd "$HOME/dev/claude-code-config" && git push' /home/akhil

# --- must stay silent (normal permission flow)
case_ allow 'vercel deploy'
case_ allow 'vercel'
case_ allow 'vercel ls'
case_ allow 'vercel inspect https://x.vercel.app'
case_ allow 'vercel logs https://x.vercel.app --level error'
case_ allow 'vercel build --prod'
case_ allow 'terraform plan -out=tfplan -input=false'
case_ allow 'terraform show tfplan'
case_ allow 'terraform validate && terraform fmt -check'
case_ allow 'tofu plan'
case_ allow 'kubectl get pods -n web --context prod'
case_ allow 'kubectl diff --server-side -f k8s/'
case_ allow 'kubectl apply --server-side --dry-run=server -f k8s/'
case_ allow 'helm template web charts/web | kubeconform -strict'
case_ allow 'helm upgrade --install web charts/web --dry-run=server'
case_ allow 'helm lint charts/web'
case_ allow 'docker compose up -d --wait'
case_ allow 'docker compose down'
case_ allow 'docker build --check .'
case_ allow 'docker system prune -f'
case_ allow 'npm publish --dry-run'
case_ allow 'npm test'
case_ allow 'pnpm install --frozen-lockfile'
case_ allow 'gh run list -L 5'
case_ allow 'gh run watch 123 --exit-status'
case_ allow 'gh release view v1.2.3'
case_ allow 'gh api repos/o/r/releases/latest --jq .tag_name'
case_ allow 'git commit -m "ci: add vercel --prod step and terraform destroy docs"'
case_ allow 'grep -rn "terraform destroy" docs/'
case_ allow 'echo "run: vercel --prod"'
case_ allow 'git push' "$HOME/dev/claude-code-config"
case_ allow 'git log --oneline -5'
case_ allow 'fly status'
case_ allow 'fly logs'
case_ allow 'wrangler deploy --dry-run'
case_ allow 'wrangler versions upload'
case_ allow 'wrangler tail'
case_ allow 'drizzle-kit generate'
case_ allow 'drizzle-kit push --explain'
case_ allow 'npx prisma migrate dev --name add_users'
case_ allow 'npx prisma migrate status'
case_ allow 'supabase db reset'
case_ allow 'supabase migration new add_users'
case_ allow 'psql "$DATABASE_URL" -c "select count(*) from users"'
case_ allow 'aws s3 ls s3://bucket'
case_ allow $'cat > deploy.sh <<\'EOF\'\nvercel --prod\nEOF'

# --- must ask
case_ ask 'vercel --prod'
case_ ask 'vercel deploy --prod --yes'
case_ ask 'npx vercel deploy --prebuilt --prod'
case_ ask 'VERCEL_ORG_ID=x vercel deploy --target=production'
case_ ask 'vercel promote https://x.vercel.app'
case_ ask 'vercel rollback'
case_ ask 'vercel env add API_KEY production'
case_ ask 'vercel rolling-release complete --dpl=x.vercel.app'
case_ ask 'fly deploy'
case_ ask 'flyctl deploy --strategy canary'
case_ ask 'fly secrets set API_KEY=x'
case_ ask 'wrangler deploy'
case_ ask 'npx wrangler versions deploy'
case_ ask 'wrangler rollback'
case_ ask 'wrangler d1 migrations apply db --remote'
case_ ask 'railway up'
case_ ask 'terraform apply tfplan'
case_ ask 'tofu apply tfplan'
case_ ask 'terraform state rm aws_db_instance.main'
case_ ask 'terraform import aws_s3_bucket.b my-bucket'
case_ ask 'kubectl apply -f k8s/ --context prod -n web'
case_ ask 'kubectl rollout undo deploy/web'
case_ ask 'helm upgrade --install web charts/web --wait'
case_ ask 'helm rollback web 3'
case_ ask 'docker push ghcr.io/me/app:abc123'
case_ ask 'docker buildx build --push -t ghcr.io/me/app:abc .'
case_ ask 'docker compose down -v'
case_ ask 'docker compose -f compose.yaml down --volumes'
case_ ask 'docker volume rm app_pgdata'
case_ ask 'docker system prune -af --volumes'
case_ ask 'npm publish'
case_ ask 'pnpm publish --access public'
case_ ask 'uv publish'
case_ ask 'gh release create v1.2.3 --verify-tag -F notes.md'
case_ ask 'gh workflow run deploy.yml -f env=production'
case_ ask 'gh secret set VERCEL_TOKEN'
case_ ask 'gh pr merge 12 --squash'
case_ ask 'gh api -X DELETE repos/o/r/git/refs/tags/v1'
case_ ask 'gh api repos/o/r/deployments --method POST -f ref=main'
case_ ask 'git push origin main'
case_ ask 'git push'
case_ ask 'git push --force-with-lease' "$HOME/dev/claude-code-config"
case_ ask 'git push origin v1.2.3 --follow-tags'
case_ ask 'git push --atomic origin HEAD:main v1.2.3'
case_ ask 'npm run build && vercel --prod'
case_ ask 'drizzle-kit push'
case_ ask 'pnpm dlx drizzle-kit push'
case_ ask 'npx prisma migrate deploy'
case_ ask 'npx prisma db push'
case_ ask 'npx prisma db migrate --db "$PRODUCTION_DATABASE_URL"'
case_ ask 'npx prisma migrate dev --shadow-database-url "$URL"'
case_ ask 'supabase db push'
case_ ask 'psql "$DATABASE_URL" -c "DROP TABLE users"'
case_ ask 'psql -c "delete from sessions;"'
case_ ask 'aws rds delete-db-instance --db-instance-identifier prod'
case_ ask 'aws s3 rm s3://bucket --recursive'
case_ ask 'gcloud sql instances delete prod-db'
case_ ask 'doppler run -- vercel deploy --prod'
case_ ask 'timeout 600 fly deploy'
case_ ask 'bash -c "fly deploy --remote-only"'
case_ ask './node_modules/.bin/vercel --prod'

case_ ask 'echo dGVycmFmb3JtIGRlc3Ryb3k= | base64 -d | sh'
case_ ask 'eval "$DEPLOY_CMD"'
case_ ask 'X=vercel${IFS}--prod; $X'

# --- unparseable input must ask, not pass silently
n=$((n+1)); out=$(printf 'not json' | bash "$g" 2>/dev/null)
if [ "$(jq -r '.hookSpecificOutput.permissionDecision' <<<"$out" 2>/dev/null)" != ask ]; then fail=$((fail+1)); echo "FAIL expect=ask   got=other  <unparseable input>"; fi

# --- bypass regressions (subshells, xargs, versioned/direct bins, global flags, scripts)
case_ deny '(cd infra; terraform destroy)'
case_ deny 'echo x | xargs terraform destroy'
case_ deny 'terraform -chdir=infra destroy'
case_ ask 'terraform -chdir=infra apply tfplan'
case_ ask 'npx --yes vercel@latest deploy --prod'
case_ ask 'pnpm vercel --prod'
case_ ask 'npm exec -- vercel --prod'
case_ ask 'vercel --scope my-team promote https://x.vercel.app'
case_ ask 'kubectl --context prod -n web apply -f k8s/'
case_ ask 'helm -n web upgrade --install web charts/web'
case_ ask 'fly -a my-app deploy'
case_ ask 'pnpm -r publish --access public'
case_ ask 'npm --workspace pkg publish'
case_ ask 'pnpm run deploy'
case_ ask 'npm run deploy:prod'
case_ ask 'pnpm db:push'
case_ ask './scripts/deploy.sh production'
case_ ask 'bash scripts/release.sh'
case_ ask 'echo $(vercel --prod)'
case_ ask 'uv run alembic downgrade base'
case_ allow 'uv run alembic upgrade head'
case_ allow 'npm run dev'
case_ allow 'node scripts/build.js'
case_ allow 'pnpm -r test'
case_ allow 'kubectl --context prod -n web get pods'
case_ allow 'terraform -chdir=infra plan -out=tfplan'

# --- must deny
case_ deny 'terraform destroy'
case_ deny 'terraform apply -auto-approve'
case_ deny 'terraform plan -destroy -out=tfplan && terraform apply -auto-approve tfplan'
case_ deny 'tofu destroy -target=aws_instance.x'
case_ deny 'terraform apply -destroy'
case_ deny 'terragrunt run-all destroy'
case_ deny 'drizzle-kit push --force'
case_ deny 'npx drizzle-kit push --force --verbose'
case_ deny 'npx prisma migrate reset --force'
case_ deny 'npx prisma db push --accept-data-loss'
case_ deny 'prisma db push --force-reset'
case_ deny 'supabase db reset --linked'
case_ deny 'kubectl delete namespace web'
case_ deny 'kubectl delete pods --all -n web'
case_ deny 'fly apps destroy my-app'
case_ deny 'fly volumes destroy vol_123'
case_ deny 'wrangler delete'
case_ deny 'gh repo delete me/app --yes'
case_ deny 'psql -c "DROP DATABASE app"'
case_ deny 'sh -c "terraform destroy -auto-approve"'
case_ deny 'pulumi destroy --yes'

echo "$n cases, $fail failed"
[ $fail -eq 0 ]
