---
name: model-compare
description: Query multiple AI models (GPT-4o, Claude Opus, Gemini) and compare their responses. Use when user wants to compare models, get multiple perspectives, or asks to query different AIs.
allowed-tools:
  - Bash
model: claude-sonnet-4-5-20250929
---

# Multi-Model Comparison

I'll query three different AI models with your question and compare their responses.

## Models Being Queried

1. **GPT-4o** (OpenAI) - Fast, capable, good at following instructions
2. **Claude Opus** (Anthropic via OpenRouter) - Strong reasoning, nuanced responses
3. **Gemini Pro 1.5** (Google via OpenRouter) - Large context, good at analysis

## Your Question

$ARGUMENTS

---

## Responses

### GPT-4o Response

```bash
curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o",
    "messages": [{"role": "user", "content": "'"$ARGUMENTS"'"}],
    "temperature": 0.7
  }' | jq -r '.choices[0].message.content // .error.message'
```

### Claude Opus Response

```bash
curl -s https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "HTTP-Referer: https://localhost" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "anthropic/claude-opus-4-20250514",
    "messages": [{"role": "user", "content": "'"$ARGUMENTS"'"}]
  }' | jq -r '.choices[0].message.content // .error.message'
```

### Gemini Pro Response

```bash
curl -s https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "HTTP-Referer: https://localhost" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "google/gemini-pro-1.5",
    "messages": [{"role": "user", "content": "'"$ARGUMENTS"'"}]
  }' | jq -r '.choices[0].message.content // .error.message'
```

---

## Comparison Summary

After receiving all responses, I'll provide:
- Key similarities between models
- Notable differences in approach
- Strengths of each response
- Recommendation based on your use case
