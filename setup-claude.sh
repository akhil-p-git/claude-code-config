#!/bin/bash

# Claude Code Dotfiles Setup Script
# Run this on any new machine to set up your Claude Code configuration

set -e  # Exit on error

echo "🚀 Setting up Claude Code configuration..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Detect script location
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "📁 Dotfiles directory: $DOTFILES_DIR"

# Create .claude directory if it doesn't exist
mkdir -p ~/.claude

# Function to backup existing file
backup_file() {
    if [ -f "$1" ]; then
        echo -e "${YELLOW}⚠️  Backing up existing $1 to $1.backup${NC}"
        cp "$1" "$1.backup"
    fi
}

# Function to create symlink
create_symlink() {
    local source=$1
    local target=$2

    if [ -L "$target" ]; then
        echo -e "${GREEN}✓${NC} Symlink already exists: $target"
    elif [ -e "$target" ]; then
        backup_file "$target"
        ln -sf "$source" "$target"
        echo -e "${GREEN}✓${NC} Created symlink: $target -> $source"
    else
        ln -sf "$source" "$target"
        echo -e "${GREEN}✓${NC} Created symlink: $target -> $source"
    fi
}

# 1. Link global settings
echo ""
echo "📝 Setting up global settings..."
create_symlink "$DOTFILES_DIR/.claude/settings.json" "$HOME/.claude/settings.json"

# 2. Link CLAUDE.md
echo ""
echo "📖 Setting up global CLAUDE.md..."
create_symlink "$DOTFILES_DIR/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

# 3. Link commands directory
echo ""
echo "⚡ Setting up custom commands..."
if [ -d "$HOME/.claude/commands" ] && [ ! -L "$HOME/.claude/commands" ]; then
    echo -e "${YELLOW}⚠️  Backing up existing commands to ~/.claude/commands.backup${NC}"
    mv "$HOME/.claude/commands" "$HOME/.claude/commands.backup"
fi
create_symlink "$DOTFILES_DIR/.claude/commands" "$HOME/.claude/commands"

# 4. Copy hooks configuration (need to merge with existing settings)
echo ""
echo "🪝 Setting up hooks..."
if [ -f "$DOTFILES_DIR/.claude/hooks-config.json" ]; then
    echo -e "${YELLOW}ℹ️  Hooks configuration available at: $DOTFILES_DIR/.claude/hooks-config.json${NC}"
    echo -e "${YELLOW}ℹ️  You may need to manually merge hooks into ~/.claude/settings.json${NC}"
fi

# 5. Check for required environment variables
echo ""
echo "🔐 Checking environment variables..."

check_env_var() {
    if [ -z "${!1}" ]; then
        echo -e "${RED}✗${NC} $1 not set"
        return 1
    else
        echo -e "${GREEN}✓${NC} $1 is set"
        return 0
    fi
}

ENV_MISSING=0

if ! check_env_var "ANTHROPIC_API_KEY"; then
    ENV_MISSING=1
fi

if ! check_env_var "GITHUB_TOKEN"; then
    ENV_MISSING=1
    echo -e "${YELLOW}  Create one at: https://github.com/settings/tokens${NC}"
fi

if [ $ENV_MISSING -eq 1 ]; then
    echo ""
    echo -e "${YELLOW}⚠️  Add missing environment variables to your shell config (~/.zshrc or ~/.bashrc):${NC}"
    echo ""
    echo "export ANTHROPIC_API_KEY='your-api-key'"
    echo "export GITHUB_TOKEN='your-github-token'"
    echo ""
fi

# 6. Install/verify Claude Code
echo ""
echo "🔍 Checking Claude Code installation..."
if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>&1 || echo "unknown")
    echo -e "${GREEN}✓${NC} Claude Code is installed: $CLAUDE_VERSION"
else
    echo -e "${RED}✗${NC} Claude Code not found"
    echo "Install from: https://code.claude.com"
fi

# 7. Verify MCP servers are available
echo ""
echo "🔌 Verifying MCP server packages..."
echo "  (Will be installed on first use by npx)"
echo "  - @modelcontextprotocol/server-git"
echo "  - @modelcontextprotocol/server-github"
echo "  - task-master-ai"

# 8. Initialize git repo for dotfiles if not already
echo ""
echo "📦 Checking dotfiles git repository..."
cd "$DOTFILES_DIR"
if [ -d ".git" ]; then
    echo -e "${GREEN}✓${NC} Dotfiles is a git repository"
    echo "  Remote: $(git remote get-url origin 2>/dev/null || echo 'No remote configured')"
else
    echo -e "${YELLOW}⚠️  Not a git repository. To make this portable, run:${NC}"
    echo "  cd $DOTFILES_DIR"
    echo "  git init"
    echo "  git add ."
    echo "  git commit -m 'Initial Claude Code configuration'"
    echo "  git remote add origin YOUR_REPO_URL"
    echo "  git push -u origin main"
fi

# 9. Test configuration
echo ""
echo "🧪 Testing configuration..."
if command -v claude &> /dev/null; then
    echo "Running: claude doctor"
    claude doctor || echo -e "${YELLOW}⚠️  Some checks failed. Review output above.${NC}"
else
    echo -e "${YELLOW}⚠️  Skipping tests - Claude Code not installed${NC}"
fi

# Summary
echo ""
echo "=========================================="
echo "✨ Setup Complete!"
echo "=========================================="
echo ""
echo -e "${GREEN}✓${NC} Global settings linked"
echo -e "${GREEN}✓${NC} CLAUDE.md linked"
echo -e "${GREEN}✓${NC} Custom commands linked"
echo ""
echo "📚 Available custom commands:"
echo "  /git-quick       - Quick git workflow"
echo "  /git-review      - Review changes with security checks"
echo "  /ask [question]  - Quick research and questions"
echo "  /security-check  - Scan for secrets and validate .gitignore"
echo "  /split-project   - Organize frontend/backend structure"
echo "  /pr              - Create GitHub pull request"
echo ""
echo "🔧 Templates available in:"
echo "  $DOTFILES_DIR/.claude/templates/"
echo ""
echo "📖 Next steps:"
echo "  1. Restart your terminal to load environment variables"
echo "  2. Run 'claude' to start a session"
echo "  3. Try '/help' to see all available commands"
echo "  4. Run '/security-check' in your projects"
echo ""
echo "🌐 To set up on another machine:"
echo "  git clone YOUR_REPO_URL ~/my-dotfiles"
echo "  cd ~/my-dotfiles"
echo "  ./setup-claude.sh"
echo ""
