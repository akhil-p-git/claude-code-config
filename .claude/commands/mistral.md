---
description: "Query Mistral Large via OpenRouter"
allowed-tools: ["Bash"]
model: "claude-sonnet-4-5-20250929"
---

# Querying Mistral Large

**Your question:** $ARGUMENTS

Let me ask Mistral for you...

! curl -s https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "HTTP-Referer: https://localhost" \
  -H "X-Title: Claude Code CLI" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"mistralai/mistral-large\",
    \"messages\": [{\"role\": \"user\", \"content\": \"$ARGUMENTS\"}]
  }" | jq -r '.choices[0].message.content // .error.message // "Error: No response"'
