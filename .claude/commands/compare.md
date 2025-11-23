---
description: "Ask multiple AI models and compare their responses"
allowed-tools: ["Bash"]
model: "claude-sonnet-4-5-20250929"
---

# Comparing Multiple AI Models

**Your question:** $ARGUMENTS

Let me ask GPT-4o, Claude Opus, and Gemini Pro, then compare their responses...

---

## 🤖 GPT-4o Response:

! curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"gpt-4o\",
    \"messages\": [{\"role\": \"user\", \"content\": \"$ARGUMENTS\"}],
    \"temperature\": 0.7
  }" | jq -r '.choices[0].message.content // .error.message // "Error: No response"'

---

## 🧠 Claude Opus Response:

! curl -s https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "HTTP-Referer: https://localhost" \
  -H "X-Title: Claude Code CLI" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"anthropic/claude-opus-4-20250514\",
    \"messages\": [{\"role\": \"user\", \"content\": \"$ARGUMENTS\"}]
  }" | jq -r '.choices[0].message.content // .error.message // "Error: No response"'

---

## 💎 Gemini Pro Response:

! curl -s https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "HTTP-Referer: https://localhost" \
  -H "X-Title: Claude Code CLI" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"google/gemini-pro-1.5\",
    \"messages\": [{\"role\": \"user\", \"content\": \"$ARGUMENTS\"}]
  }" | jq -r '.choices[0].message.content // .error.message // "Error: No response"'

---

## 📊 Summary

I've queried three different AI models with your question. Compare their responses above to see different perspectives and approaches to your query.
