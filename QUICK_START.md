# Quick Start Guide

## 1. Set Environment Variables (5 min)

Add these to `~/.zshrc` or `~/.bashrc`:

```bash
# Open your shell config
nano ~/.zshrc  # or ~/.bashrc for bash

# Add these lines (replace with your actual keys)
export ANTHROPIC_API_KEY='sk-ant-...'
export GITHUB_TOKEN='ghp_...'

# Save and reload
source ~/.zshrc
```

### Getting API Keys

**ANTHROPIC_API_KEY:**
- Go to https://console.anthropic.com/settings/keys
- Create a new API key
- Copy and paste into your shell config

**GITHUB_TOKEN:**
- Go to https://github.com/settings/tokens
- Click "Generate new token (classic)"
- Select scopes: `repo`, `read:org`, `read:user`
- Generate and copy the token

## 2. Verify Setup (2 min)

```bash
# Check environment variables
echo $ANTHROPIC_API_KEY  # Should show your key
echo $GITHUB_TOKEN       # Should show your token

# Verify symlinks
ls -la ~/.claude/
# Should see symlinks pointing to ~/my-dotfiles/.claude/

# List custom commands
ls ~/.claude/commands/
# Should show: ask.md, git-quick.md, git-review.md, pr.md, security-check.md, split-project.md
```

## 3. Test It Out (3 min)

```bash
# Start Claude Code
claude

# Try a custom command
/security-check

# Ask a question
/ask how do I implement authentication in React?

# Run git workflow
/git-quick
```

## 4. Make It Portable (5 min)

```bash
cd ~/my-dotfiles

# Create GitHub repo (or use GitLab, Bitbucket, etc.)
# Go to https://github.com/new and create a repo called "claude-dotfiles"

# Push your config
git remote add origin git@github.com:YOUR_USERNAME/claude-dotfiles.git
git branch -M main
git push -u origin main
```

## 5. Set Up on Another Machine

```bash
# Clone your dotfiles
git clone git@github.com:YOUR_USERNAME/claude-dotfiles.git ~/my-dotfiles

# Run setup
cd ~/my-dotfiles
./setup-claude.sh

# Add environment variables to ~/.zshrc
# Restart terminal

# Done!
```

## Daily Workflow

### Starting a Project

```bash
# Navigate to project
cd ~/my-project

# Copy appropriate .gitignore
cp ~/.claude/templates/gitignore-fullstack .gitignore

# Run security check
claude
/security-check

# Start coding!
```

### Before Committing Code

```bash
# Review changes with security checks
claude
/git-review

# If all good, quick commit
/git-quick
```

### Creating a PR

```bash
# Create pull request with auto-generated description
claude
/pr
```

### Quick Questions

```bash
# Ask anything with project context
claude
/ask how do I optimize this React component?
/ask what's the best way to handle authentication?
/ask help me debug this error
```

## Customization

### Add Your Own Command

```bash
# Create a new command file
nano ~/my-dotfiles/.claude/commands/my-command.md
```

Example:
```markdown
---
description: "My custom command"
allowed-tools: ["Read", "Bash"]
---

Your command instructions here.

! git status  # Run bash commands with !
```

### Update Settings

```bash
# Edit global settings
nano ~/my-dotfiles/.claude/settings.json

# Commit changes
cd ~/my-dotfiles
git add .
git commit -m "Update settings"
git push
```

## Troubleshooting

### Commands Not Found

```bash
# Check symlink
ls -la ~/.claude/commands

# Re-run setup
cd ~/my-dotfiles
./setup-claude.sh
```

### MCP Servers Not Working

```bash
# Start Claude and check
claude
/mcp

# Verify environment variables
echo $GITHUB_TOKEN
echo $ANTHROPIC_API_KEY
```

### Need Help?

- Check the full README.md in this repo
- Run `/help` in Claude Code
- Check official docs: https://code.claude.com/docs

## Pro Tips

1. Run `/security-check` before every commit
2. Use `/git-review` to catch issues before pushing
3. Ask questions with `/ask` - it has full project context
4. Keep `.taskmaster/` in .gitignore (never commit it)
5. Update your dotfiles repo when you add new commands
6. The CLAUDE.md file guides all code generation - customize it!

Happy coding!
