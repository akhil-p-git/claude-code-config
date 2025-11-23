---
description: "Query GPT-3.5 Turbo (fast and cost-effective)"
allowed-tools: ["Bash"]
model: "claude-sonnet-4-5-20250929"
---

# Querying GPT-3.5 Turbo

**Your question:** $ARGUMENTS

Let me ask GPT-3.5 Turbo for you (fast response)...

! curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"gpt-3.5-turbo\",
    \"messages\": [{\"role\": \"user\", \"content\": \"$ARGUMENTS\"}],
    \"temperature\": 0.7
  }" | jq -r '.choices[0].message.content // .error.message // "Error: No response"'
