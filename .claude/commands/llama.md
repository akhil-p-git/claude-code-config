---
description: "Query Meta Llama 3.1 405B via OpenRouter"
allowed-tools: ["Bash"]
model: "claude-sonnet-4-5-20250929"
---

# Querying Llama 3.1 405B

**Your question:** $ARGUMENTS

Let me ask Llama for you...

! curl -s https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "HTTP-Referer: https://localhost" \
  -H "X-Title: Claude Code CLI" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"meta-llama/llama-3.1-405b-instruct\",
    \"messages\": [{\"role\": \"user\", \"content\": \"$ARGUMENTS\"}]
  }" | jq -r '.choices[0].message.content // .error.message // "Error: No response"'
