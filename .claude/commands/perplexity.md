---
description: "Query Perplexity Sonar (web-connected AI with citations)"
allowed-tools: ["Bash"]
model: "claude-sonnet-4-5-20250929"
---

# Querying Perplexity Sonar

**Your question:** $ARGUMENTS

Let me search the web and get you an answer with citations...

! curl -s https://api.perplexity.ai/chat/completions \
  -H "Authorization: Bearer $PERPLEXITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"sonar\",
    \"messages\": [{\"role\": \"user\", \"content\": \"$ARGUMENTS\"}]
  }" | jq -r '.choices[0].message.content // .error.message // "Error: No response"'
