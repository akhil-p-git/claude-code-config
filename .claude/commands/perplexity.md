---
description: "Query Perplexity Sonar (web-connected AI with citations)"
allowed-tools: ["Bash"]
model: "claude-sonnet-4-5-20250929"
---

# Querying Perplexity Sonar

**Your question:** $ARGUMENTS

Let me search the web and get you an answer with citations...

! curl -s https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "HTTP-Referer: https://localhost" \
  -H "X-Title: Claude Code CLI" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"perplexity/llama-3.1-sonar-large-128k-online\",
    \"messages\": [{\"role\": \"user\", \"content\": \"$ARGUMENTS\"}]
  }" | jq -r '.choices[0].message.content // .error.message // "Error: No response"'
