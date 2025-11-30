---
description: "List ALL available models: both native Claude models and external AI models"
allowed-tools: ["Bash"]
model: "claude-sonnet-4-5-20250929"
---

# All Available Models

This lists **every** model available in your Claude Code setup.

---

## Your Subscriptions Quick Reference

| Subscription | Access Method | Best For |
|-------------|---------------|----------|
| **Claude Max** | Native (`/model`) | Implementation, multi-file editing |
| **Cursor Max** | Cursor IDE | Autocomplete, in-flow coding |
| **ChatGPT Plus** | Web app / `/gpt4o` | Brainstorming, diagrams |
| **Gemini Pro** | Web app / `/gemini` | Large context (1M tokens) |
| **Perplexity Pro** | Web app / `/perplexity` | Real-time research with citations |

---

## Native Claude Models (via `/model` command)

**Switch Claude Code's main model:**
- `/model sonnet` - Claude Sonnet 4.5 (current default, balanced performance)
- `/model opus` - Claude Opus 4 (most capable reasoning)
- `/model haiku` - Claude Haiku (fastest, for simple tasks)
- `/model sonnet[1m]` - Claude Sonnet with 1 million token context
- `/model opusplan` - Auto-switches between Opus and Sonnet based on task
- `/model default` - Recommended model for your account

*These change which Claude model powers Claude Code itself.*

---

## OpenAI Models (via slash commands)

**Available via your configured OpenAI API:**
- `/gpt4o your question` - GPT-4o (latest, fastest) ★ Best for quick questions
- `/gpt4 your question` - GPT-4 (standard)
- `/o1 your question` - OpenAI o1 (advanced reasoning) ★ Best for math/logic
- `/gpt35 your question` - GPT-3.5 Turbo (fast, cost-effective)

*Also available:*
- `gpt-4-turbo` - GPT-4 Turbo
- `o1-mini` - Fast reasoning variant

---

## OpenRouter Models (via slash commands)

**Top models via your OpenRouter API:**
- `/opus your question` - Claude Opus 4 (most capable Claude) ★ Best for complex tasks
- `/gemini your question` - Google Gemini Pro 1.5 ★ Best for large context
- `/llama your question` - Meta Llama 3.1 405B
- `/deepseek your question` - DeepSeek V3 ★ Best budget option
- `/mistral your question` - Mistral Large
- `/perplexity your question` - Perplexity Sonar ★ Best for web research

**Other notable OpenRouter models:**
- `anthropic/claude-sonnet-4-20250514` - Claude Sonnet 4 via OpenRouter
- `openai/gpt-4-turbo` - GPT-4 via OpenRouter
- `mistralai/mixtral-8x22b-instruct` - Powerful open model
- `cohere/command-r-plus` - Cohere's flagship

**Get the full OpenRouter catalog:**

! curl -s https://openrouter.ai/api/v1/models \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" | \
  jq -r '.data[] | "\(.id) - \(.name // "N/A")"' | head -50

---

## Special Commands

- `/query model-id your question` - Query any OpenRouter model by exact ID
- `/compare your question` - Query multiple models simultaneously
- `/ask your question` - Quick research with project context
- `/perplexity your question` - Web-connected search with citations

---

## Model Selection Guide

| Task | Best Model | Command |
|------|------------|---------|
| Quick coding question | GPT-4o | `/gpt4o` |
| Complex reasoning | Claude Opus | `/opus` |
| Math/logic puzzles | OpenAI o1 | `/o1` |
| Large codebase analysis | Gemini Pro | `/gemini` |
| Real-time web research | Perplexity Sonar | `/perplexity` |
| Budget-friendly | DeepSeek | `/deepseek` |
| Multiple perspectives | Compare | `/compare` |
| Open source preference | Llama | `/llama` |

---

## Key Differences

**Native models (`/model`):**
- Switch the underlying Claude model that runs Claude Code
- Affects all responses and tool usage
- Persistent for the session

**External models (slash commands):**
- Send one-off queries to other AI models
- Return responses within Claude Code chat
- Don't change Claude Code's behavior

**Examples:**
```bash
# Switch Claude Code to use Opus
/model opus

# Ask GPT-4 a specific question (while Claude Code stays on current model)
/gpt4 Explain quantum computing in simple terms

# Research with web access
/perplexity What are the latest React 19 features?

# Compare responses from multiple models
/compare What's the best programming language for web development?
```

---

## See Also

- [WORKFLOW.md](../../WORKFLOW.md) - Optimal workflow for your subscriptions
- [COMMANDS_REFERENCE.md](../../COMMANDS_REFERENCE.md) - All command details

Visit https://openrouter.ai/models for detailed pricing and OpenRouter capabilities.
