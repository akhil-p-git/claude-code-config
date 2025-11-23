---
description: "Query any OpenRouter model by ID"
allowed-tools: ["Bash"]
model: "claude-sonnet-4-5-20250929"
---

# Query Custom Model

**Usage:** `/query MODEL_ID your question here`

**Example:** `/query anthropic/claude-3.5-sonnet how do I use Redis?`

---

**Processing your request...**

! if [ -z "$ARGUMENTS" ]; then \
    echo "❌ Error: Please provide a model ID and question."; \
    echo ""; \
    echo "Usage: /query MODEL_ID your question"; \
    echo ""; \
    echo "Examples:"; \
    echo "  /query anthropic/claude-3.5-sonnet explain async/await"; \
    echo "  /query google/gemini-flash-1.5 what is the fastest sorting algorithm?"; \
    echo "  /query meta-llama/llama-3.1-70b-instruct write a Python function"; \
    echo ""; \
    echo "Run /models to see all available model IDs."; \
  else \
    MODEL_ID=$(echo "$ARGUMENTS" | awk '{print $1}'); \
    QUESTION=$(echo "$ARGUMENTS" | cut -d' ' -f2-); \
    echo "🤖 Model: $MODEL_ID"; \
    echo "❓ Question: $QUESTION"; \
    echo ""; \
    echo "📡 Response:"; \
    echo ""; \
    curl -s https://openrouter.ai/api/v1/chat/completions \
      -H "Authorization: Bearer $OPENROUTER_API_KEY" \
      -H "HTTP-Referer: https://localhost" \
      -H "X-Title: Claude Code CLI" \
      -H "Content-Type: application/json" \
      -d "{
        \"model\": \"$MODEL_ID\",
        \"messages\": [{\"role\": \"user\", \"content\": \"$QUESTION\"}]
      }" | jq -r '.choices[0].message.content // .error.message // "Error: No response"'; \
  fi
