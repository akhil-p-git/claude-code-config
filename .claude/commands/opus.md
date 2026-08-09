---
description: "Query Claude Opus 4 via OpenRouter (needs OPENROUTER_API_KEY; your local model is already newer)"
allowed-tools: ["Bash"]
model: sonnet
---

# Querying Claude Opus 4

**Your question:** $ARGUMENTS

Let me ask Claude Opus for you...

! curl -s https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "HTTP-Referer: https://localhost" \
  -H "X-Title: Claude Code CLI" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"anthropic/claude-opus-4-20250514\",
    \"messages\": [{\"role\": \"user\", \"content\": \"$ARGUMENTS\"}]
  }" | jq -r '.choices[0].message.content // .error.message // "Error: No response"'
