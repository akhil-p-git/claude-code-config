#!/bin/bash
# Registers the local MCP servers this setup uses, at user scope, on any machine:
#   godot-mcp          Godot editor control (needs the Godot editor with the GDAI addon running)
#   game-asset-finder  searches free game asset libraries
# Both are third-party code, cloned at the exact commits that were reviewed. Bump a pin only after
# reading the diff. The claude.ai connectors (Gmail, Drive, Calendar, Docs) follow your account
# login, and the vercel and context7 servers come from plugins (setup-claude.sh); neither is done here.
#
# Usage: setup-mcp.sh [godot-mcp] [game-asset-finder]   (default: both; safe to re-run)
# Needs: git, claude, plus uv (godot-mcp) and node >= 20.18.1 with npm (game-asset-finder).
set -euo pipefail

TOOLS="${TOOLS_DIR:-$HOME/work/Dev/tools}"

GODOT_URL="https://github.com/PiMPStudios/Claude-GoDot-MCP.git"
GODOT_SHA="cdaf821b142c68e4bb81a4cfa3d17f8f35a8eec3"      # 2026-07-08 "fix: harden HTTP reads, ..."
ASSET_URL="https://github.com/sudoriaa/game-asset-finder-mcp.git"
ASSET_SHA="f5efb9f0d0de154e2629e0a4b96e6c9570734609"      # 2026-08-18 "Initial release"

if [ $# -gt 0 ]; then servers="$*"; else servers="godot-mcp game-asset-finder"; fi

need() { # tool, how to get it
  command -v "$1" >/dev/null 2>&1 || { echo "✗ $1 not found: $2" >&2; return 1; }
}

# Clones $url into $dir if needed and checks out $sha. Sets CHANGED=1 if the checkout moved.
checkout_pinned() {
  local url=$1 dir=$2 sha=$3
  CHANGED=0
  if [ ! -d "$dir/.git" ]; then
    mkdir -p "$(dirname "$dir")"
    git clone --quiet "$url" "$dir"
    CHANGED=1
  fi
  if [ "$(git -C "$dir" rev-parse HEAD)" != "$sha" ]; then
    if [ -n "$(git -C "$dir" status --porcelain)" ]; then
      echo "✗ $dir has local changes; not moving it to the pinned commit" >&2
      return 1
    fi
    git -C "$dir" fetch --quiet "$url"      # by URL: an existing clone's origin may be stale
    git -C "$dir" checkout --quiet --detach "$sha"
    CHANGED=1
  fi
  [ "$(git -C "$dir" rev-parse HEAD)" = "$sha" ] || { echo "✗ $dir is not at $sha" >&2; return 1; }
}

registered() { claude mcp get "$1" >/dev/null 2>&1; }

setup_godot() {
  need uv "brew install uv (macOS) or https://docs.astral.sh/uv/" || return 1
  local dir="$TOOLS/Claude-GoDot-MCP"
  checkout_pinned "$GODOT_URL" "$dir" "$GODOT_SHA" || return 1
  [ "$CHANGED" = 1 ] && uv sync --frozen --directory "$dir/python"
  if registered godot-mcp; then echo "✓ godot-mcp already registered (left as is)"; return 0; fi
  claude mcp add -s user godot-mcp \
    -e GODOT_HOST=127.0.0.1 -e GDAI_MCP_SERVER_PORT=3571 \
    -- uv --directory "$dir/python" run python -m mcp_server
  echo "✓ godot-mcp registered (it works only while the Godot editor with the GDAI addon is open)"
}

setup_assets() {
  need node "install Node >= 20.18.1 (fnm, nvm or brew install node)" || return 1
  need npm "comes with Node" || return 1
  local dir="$TOOLS/game-asset-finder-mcp"
  checkout_pinned "$ASSET_URL" "$dir" "$ASSET_SHA" || return 1
  if [ "$CHANGED" = 1 ] || [ ! -f "$dir/dist/index.js" ]; then
    (cd "$dir" && npm ci --silent && npm run --silent build)
  fi
  if registered game-asset-finder; then echo "✓ game-asset-finder already registered (left as is)"; return 0; fi
  claude mcp add -s user game-asset-finder \
    -e GAME_ASSET_DATA_DIR="$TOOLS/game-asset-finder-data" \
    -- node "$dir/dist/index.js"
  echo "✓ game-asset-finder registered"
}

need git "install git" && need claude "install Claude Code" || exit 1
status=0
for s in $servers; do
  case "$s" in
    godot-mcp)         setup_godot  || status=1 ;;
    game-asset-finder) setup_assets || status=1 ;;
    *) echo "✗ unknown server '$s' (godot-mcp, game-asset-finder)" >&2; status=1 ;;
  esac
done
echo "Check with: claude mcp list"
exit $status
