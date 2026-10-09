#!/usr/bin/env bash
# Runs every hook test suite. Each suite builds its own fixtures under tests/fx (fresh
# mktemp dirs) and redirects state/log paths into the scratch area; nothing outside this
# folder is read or written apart from read-only access to the repo's capture-lesson.sh.
here="$(cd "$(dirname "$0")" && pwd)"
bash "$here/setup-fixtures.sh" >/dev/null
rc=0
for s in run-guard-tests run-protect-tests run-format-tests run-secret-tests run-verify-tests run-lesson-tests run-git-secrets-tests; do
  echo "== $s"; bash "$here/$s.sh" 2>&1 | tail -4 || rc=1
done
exit $rc
