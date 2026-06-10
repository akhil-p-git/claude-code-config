# Claude Code Ultimate Configuration

🚀 **The complete Claude Code setup with custom commands, AI models, and specialized agents**

Transform your Claude Code CLI into a powerhouse development environment with:
- **6 Git workflow commands** for effortless version control
- **12 AI model integrations** (GPT-4, Claude Opus, Gemini, Llama, and more)
- **11 specialized AI agents** (code reviewers, security auditors, performance optimizers)
- **Security-first approach** with automatic secret detection
- **100% portable** across all your machines

---

## 📚 Documentation

- **[WORKFLOW.md](WORKFLOW.md)** - Optimal AI workflow for your subscriptions (Claude, Cursor, ChatGPT, Gemini, Perplexity)
- **[COMMANDS_REFERENCE.md](COMMANDS_REFERENCE.md)** - Complete guide to all commands, models, and agents
- **[QUICK_START.md](QUICK_START.md)** - 5-minute setup guide
- **[AGENTS_GUIDE.md](AGENTS_GUIDE.md)** - Detailed guide to specialized AI agents
- **[MODEL_USAGE.md](MODEL_USAGE.md)** - Multi-model configuration and usage
- **[.env.example](.env.example)** - Required environment variables

---

## ⚡ Quick Access

```bash
# Start Claude Code
claude

# Git workflows
/git-quick      # Quick commit and push
/git-review     # Security-aware code review
/pr             # Create GitHub pull request

# AI models
/gpt4o [question]     # Fast GPT-4
/opus [question]      # Powerful Claude Opus
/perplexity [question] # Web-connected research
/compare [question]   # Ask multiple models

# Specialized agents
@code-reviewer        # Review code quality
@security-auditor     # Security audit
@frontend-expert      # React/UI help

# Utilities
/security-check       # Scan for secrets
/ask [question]       # Quick Q&A
/agents              # List all agents
/models              # List all AI models
```

---

## Features

- **Global Settings** - Unified configuration with MCP servers for Git, GitHub, and Taskmaster
- **Security First** - Hooks to prevent committing secrets, .env files, and .taskmaster/ directories
- **Custom Commands** - Powerful slash commands for common workflows
- **Portable** - One-command setup on any new machine
- **Stack-Optimized** - Configured for JavaScript/TypeScript, React, Python, C, and Node.js

## Quick Start

### First Time Setup

```bash
# Clone this repo
git clone YOUR_REPO_URL ~/my-dotfiles

# Run setup script
cd ~/my-dotfiles
./setup-claude.sh
```

### Required Environment Variables

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
export ANTHROPIC_API_KEY='your-api-key-here'
export GITHUB_TOKEN='your-github-token-here'
```

Then restart your terminal or run `source ~/.zshrc`

## What's Included

### 📁 Directory Structure

```
my-dotfiles/
├── .claude/
│   ├── settings.json          # Global Claude Code settings
│   ├── CLAUDE.md              # Coding standards & guidelines
│   ├── hooks/                 # Hook scripts (wired in settings.json)
│   ├── commands/              # Custom slash commands
│   │   ├── git-quick.md       # Quick git workflow
│   │   ├── git-review.md      # Review with security checks
│   │   ├── ask.md             # Research & questions
│   │   ├── security-check.md  # Security audit
│   │   ├── split-project.md   # Frontend/backend organization
│   │   └── pr.md              # Create GitHub PR
│   └── templates/             # .gitignore templates
│       ├── gitignore-fullstack
│       ├── gitignore-react
│       └── gitignore-python
├── setup-claude.sh            # Setup script for new machines
└── README.md                  # This file
```

### ⚡ Custom Slash Commands

| Command | Description |
|---------|-------------|
| `/git-quick` | Quick git workflow: status, stage, commit, push |
| `/git-review` | Comprehensive review with security and quality checks |
| `/ask [question]` | Quick research with project context |
| `/security-check` | Scan for secrets, validate .gitignore |
| `/split-project` | Organize project into frontend/backend structure |
| `/pr` | Create GitHub pull request with intelligent description |

### 🔌 MCP Servers

Pre-configured integrations:

- **Git** - Advanced git operations
- **GitHub** - PR management, issues, CI status
- **Taskmaster** - AI-powered task management

### 🛡️ Security Features

Automatic hooks that prevent:
- ✗ Committing `.env` files
- ✗ Committing `.taskmaster/` directories
- ✗ Staging files with `git add *.env`
- ✓ Validates `.gitignore` includes critical entries

### 📋 Coding Standards (CLAUDE.md)

Global coding standards include:
- Frontend/backend separation guidelines
- Language-specific best practices (JS/TS, React, Python, C, Node.js)
- Security requirements (never commit secrets)
- Testing standards (80% coverage minimum)
- Git commit message format
- Code review checklist

## Usage

### Starting a Session

```bash
# Interactive session
claude

# One-off question
claude -p "your question here"

# Continue previous conversation
claude --continue
```

### Using Custom Commands

```bash
# In a Claude session
/git-quick
/security-check
/ask how do I implement authentication?
```

### Project Setup

For new projects, copy the appropriate .gitignore:

```bash
# Full-stack project
cp ~/.claude/templates/gitignore-fullstack .gitignore

# React project
cp ~/.claude/templates/gitignore-react .gitignore

# Python project
cp ~/.claude/templates/gitignore-python .gitignore
```

### Validating Configuration

```bash
# Check everything is working
claude doctor

# View loaded configuration
claude
/config

# Check MCP servers
claude
/mcp

# View permissions
/permissions
```

## Customization

### Adding Your Own Commands

Create a new markdown file in `.claude/commands/`:

```markdown
---
description: "Your command description"
allowed-tools: ["Read", "Bash", "Write"]
model: "claude-sonnet-4-5-20250929"
---

Your command instructions here.

Use $ARGUMENTS to access command arguments.

! git status  # Execute bash commands with !
```

### Modifying Settings

Edit `~/my-dotfiles/.claude/settings.json` and run `./setup-claude.sh` again.

### Adding New Hooks

Add the hook under the `hooks` key in `~/my-dotfiles/.claude/settings.json` (put any
script in `.claude/hooks/` and `chmod +x` it). Hooks load from `settings.json`
directly — there is no separate file to merge.

## Syncing Across Machines

### Initial Setup (Machine 1)

```bash
cd ~/my-dotfiles
git init
git add .
git commit -m "Initial Claude Code configuration"
git remote add origin git@github.com:yourusername/claude-dotfiles.git
git push -u origin main
```

### Setup on Machine 2+

```bash
git clone git@github.com:yourusername/claude-dotfiles.git ~/my-dotfiles
cd ~/my-dotfiles
./setup-claude.sh
```

### Updating Configuration

```bash
cd ~/my-dotfiles
# Make changes...
git add .
git commit -m "Update configuration"
git push

# On other machines
cd ~/my-dotfiles
git pull
```

## Cursor Integration

This configuration works seamlessly with Cursor:

1. Open Cursor
2. Install "Claude Code" extension from marketplace
3. Use the sidebar or integrated terminal

All settings, commands, and MCP servers work identically in Cursor and VS Code.

## Troubleshooting

### MCP Servers Not Working

```bash
# Check server status
claude
/mcp

# Verify environment variables
echo $GITHUB_TOKEN
echo $ANTHROPIC_API_KEY

# Test server manually
npx -y @modelcontextprotocol/server-git
```

### Hooks Not Firing

Hooks live under the `hooks` key in `settings.json`. Confirm they're registered and the scripts are executable:

```bash
jq '.hooks | keys' ~/.claude/settings.json        # list configured hook events
ls -l ~/dev/claude-code-config/.claude/hooks/      # scripts should be -rwxr-xr-x
```

### Commands Not Showing Up

```bash
# Verify symlink
ls -la ~/.claude/commands

# Should point to: ~/my-dotfiles/.claude/commands

# Re-run setup
cd ~/my-dotfiles
./setup-claude.sh
```

### Permission Errors

```bash
# Check settings
claude
/permissions

# Allow specific commands
# Edit ~/.claude/settings.json and add to "permissions.allow"
```

## Best Practices

1. **Never commit secrets** - Always use `.env` files (gitignored)
2. **Run `/security-check`** before pushing code
3. **Use `/git-review`** before creating commits
4. **Keep .taskmaster/ gitignored** - Personal task management only
5. **Split frontend/backend** - Use `/split-project` for organization
6. **Update dependencies** - Run `npm audit` or `pip check` regularly

## Contributing

This is a personal configuration, but feel free to fork and customize for your needs!

## Resources

- [Claude Code Documentation](https://code.claude.com/docs)
- [MCP Documentation](https://modelcontextprotocol.io)
- [GitHub Tokens](https://github.com/settings/tokens)

## License

MIT - Feel free to use and modify as needed.
