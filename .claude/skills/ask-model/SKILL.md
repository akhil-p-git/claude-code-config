---
name: ask-model
description: Get a second opinion from a non-Claude model (GPT, Gemini, Grok, DeepSeek, Kimi, GLM, Perplexity web search with citations, or any OpenRouter model ID), or ask several at once and compare. Use when the user asks what another model thinks, wants a cross-check, says "ask GPT/Gemini/Grok/Perplexity", or runs /ask-model.
argument-hint: "[gpt|gemini|grok|deepseek|perplexity|compare|models|<vendor/model-id>] <question>"
---

# Ask another model

Replaces the old per-model commands (`/gpt4o`, `/gemini`, `/compare`, …), which pinned dead model IDs and broke on any quote in the question.

## 1. Parse `$ARGUMENTS`
- First token = target: an alias (`gpt`, `gemini`, `grok`, `deepseek`, `kimi`, `glm`, `perplexity`, `perplexity-deep`, … — run `llm.sh aliases` for the table), a full OpenRouter ID containing `/`, `compare` (optionally followed by aliases), or `models [filter]`.
- No target given → default to `compare`. No question given → ask for it.
- Aliases track OpenRouter's self-updating `~vendor/family-latest` IDs; never hardcode a dated model ID.

## 2. Build the prompt
- The other model has **no access** to this repo or conversation. Include exactly the context it needs: the question, relevant code/error excerpts, constraints.
- The prompt goes to a third-party API. **Never include** secrets, `.env` contents, credentials, or private data the user hasn't approved sending.

## 3. Run it — prompt on stdin via a quoted heredoc (no shell expansion, quotes are safe)
```bash
~/.claude/skills/ask-model/scripts/llm.sh gemini <<'__ASK_MODEL_PROMPT__'
<prompt text>
__ASK_MODEL_PROMPT__
```
- Compare: `llm.sh compare` (default gpt, gemini, grok, deepseek in parallel) or `llm.sh compare gpt perplexity`.
- List live models: `llm.sh models gemini` (no key needed).
- Exit code 3 = `OPENROUTER_API_KEY` missing: relay the script's setup instructions; don't try to locate or read keys yourself.

## 4. Report
- Show each answer (summarize if long), labeled with the resolved model ID the script prints.
- Then give your own assessment: where they agree or disagree with each other and with you, and which claims you verified. Other models hallucinate too — check factual claims and code against the source before relying on them.
