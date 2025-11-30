---
description: "List all available AI models across providers"
allowed-tools: ["Bash"]
model: "claude-sonnet-4-5-20250929"
---

# Available AI Models

Here are all the models you can access with your configured API keys:

## 🔵 OpenAI Models (via /gpt4, /gpt4o, /o1)

**Available:**
- `gpt-4o` - Latest, fastest GPT-4 (use `/gpt4o`)
- `gpt-4` - Standard GPT-4 (use `/gpt4`)
- `gpt-4-turbo` - GPT-4 Turbo
- `o1-preview` - Advanced reasoning (use `/o1`)
- `o1-mini` - Fast reasoning
- `gpt-3.5-turbo` - Fast, cost-effective

## 🟠 OpenRouter Models (via /opus, /gemini, /llama, etc.)

**Top Models:**
- `anthropic/claude-opus-4-20250514` - Most capable Claude (use `/opus`)
- `anthropic/claude-sonnet-4-20250514` - Balanced Claude
- `google/gemini-pro-1.5` - Google's flagship (use `/gemini`)
- `meta-llama/llama-3.1-405b-instruct` - Largest Llama (use `/llama`)
- `deepseek/deepseek-chat` - Cost-effective reasoning (use `/deepseek`)
- `openai/gpt-4-turbo` - GPT-4 via OpenRouter
- `mistralai/mixtral-8x22b-instruct` - Powerful open model
- `cohere/command-r-plus` - Cohere's flagship
- `perplexity/llama-3.1-sonar-large-128k-online` - Web-connected

**Fetching full OpenRouter model list...**

! curl -s https://openrouter.ai/api/v1/models \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" | \
  jq -r '.data[] | "\(.id) - \(.name // "N/A")"' | head -30

---

## 💡 How to Use

**Pre-made commands:**
- `/gpt4 your question` - OpenAI GPT-4
- `/gpt4o your question` - OpenAI GPT-4o (latest)
- `/o1 your question` - OpenAI o1 (reasoning)
- `/opus your question` - Claude Opus
- `/gemini your question` - Google Gemini
- `/llama your question` - Meta Llama
- `/deepseek your question` - DeepSeek V3
- `/mistral your question` - Mistral Large
- `/perplexity your question` - Perplexity Sonar (web-connected)
- `/compare your question` - Query multiple models at once

**Custom model:**
Use `/query model-id your question` to query any OpenRouter model by ID.

**Complete reference:**
Use `/allmodel` for full model list with selection guide.

**Full model list:**
Visit https://openrouter.ai/models for detailed pricing and capabilities.
