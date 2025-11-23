# Multi-Model Configuration

## API Keys Configured

Your environment now has access to:
- ✅ **Anthropic** (Claude) - Primary for Claude Code CLI
- ✅ **OpenAI** (GPT models) - Available for MCP servers and tools
- ✅ **OpenRouter** (Multiple models) - Available for MCP servers and tools
- ✅ **GitHub** - For GitHub MCP integration

## How Claude Code Uses These Keys

### Claude Code CLI
The `claude` CLI command uses **Anthropic API** exclusively for the assistant. It cannot directly use OpenAI or OpenRouter models.

Your active model: **Claude Sonnet 4.5** (default)

### Where Other API Keys Are Used

Your OpenAI and OpenRouter keys are available for:

1. **MCP Servers** - Any MCP server can use these keys
2. **Custom Tools** - Scripts and commands you create
3. **Other CLIs** - Tools like `openai`, `llm`, etc.

## Available Through Environment

All keys are set in `~/.zshrc` and available to any process:

```bash
echo $ANTHROPIC_API_KEY  # Claude Code
echo $OPENAI_API_KEY     # OpenAI tools
echo $OPENROUTER_API_KEY # OpenRouter
echo $GITHUB_TOKEN       # GitHub integration
```

## Using OpenAI or Other Models

While Claude Code CLI uses Claude models, you can use other models through:

### Option 1: MCP Servers
Create custom MCP servers that use OpenAI/OpenRouter APIs

### Option 2: Custom Commands
Add slash commands that call OpenAI directly:

```bash
# Example: .claude/commands/gpt.md
---
description: "Query GPT-4 via OpenAI API"
allowed-tools: ["Bash"]
---

Query GPT-4:

! curl https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4",
    "messages": [{"role": "user", "content": "$ARGUMENTS"}]
  }'
```

### Option 3: Use OpenRouter for Multiple Models
OpenRouter provides access to Claude, GPT, and many other models:

```bash
# Query via OpenRouter
curl https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "anthropic/claude-3.5-sonnet",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

## Security Note

⚠️ **IMPORTANT**: The API keys in your `~/.zshrc` are currently exposed from the chat conversation. When you have time, please:

1. Revoke all keys at their respective platforms
2. Generate new keys
3. Update `~/.zshrc` with the new keys
4. Run `source ~/.zshrc`

### How to Rotate Keys

**Anthropic**: https://console.anthropic.com/settings/keys
**OpenAI**: https://platform.openai.com/api-keys
**OpenRouter**: https://openrouter.ai/keys
**GitHub**: https://github.com/settings/tokens

## Testing Your Setup

```bash
# Test Anthropic (Claude Code)
claude -p "test message"

# Test OpenAI (direct)
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"

# Test GitHub
gh api user

# Verify all keys loaded
env | grep -E "ANTHROPIC|OPENAI|OPENROUTER|GITHUB_TOKEN"
```

All keys are now available and working in your environment!
