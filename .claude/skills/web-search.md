---
name: web-search
description: Real-time web search using Perplexity Sonar for current information, news, documentation, or anything requiring up-to-date data. Use when user needs current information, latest news, recent updates, or anything that may have changed after training cutoff.
allowed-tools:
  - Bash
model: claude-sonnet-4-5-20250929
---

# Web Search with Perplexity

I'll search the web for current information using Perplexity Sonar.

## Your Query

$ARGUMENTS

---

## Search Results

```bash
curl -s https://api.perplexity.ai/chat/completions \
  -H "Authorization: Bearer $PERPLEXITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "sonar",
    "messages": [{"role": "user", "content": "'"$ARGUMENTS"'"}]
  }' | jq -r '.choices[0].message.content // .error.message'
```

---

## When This Skill is Used

This skill activates automatically for:
- "What's the latest..." / "What's new in..."
- "Current status of..."
- "Recent news about..."
- "Is [X] still [Y]?"
- Documentation lookups ("how do I X in 2025/2026")
- Package/library version questions
- API/service status checks
- Any question needing real-time data

## Perplexity Models Available

| Model | Best For |
|-------|----------|
| `sonar` | General web search (default) |
| `sonar-pro` | Complex research, multi-step queries |
| `sonar-reasoning` | Questions requiring analysis |
