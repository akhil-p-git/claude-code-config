---
description: "Query OpenAI GPT-4o (latest, faster)"
allowed-tools: ["Bash"]
model: "claude-sonnet-4-5-20250929"
---

# Querying GPT-4o

**Your question:** $ARGUMENTS

Let me ask GPT-4o for you...

! curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"gpt-4o\",
    \"messages\": [{\"role\": \"user\", \"content\": \"$ARGUMENTS\"}],
    \"temperature\": 0.7
  }" | jq -r '.choices[0].message.content // .error.message // "Error: No response"'
