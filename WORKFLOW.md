# AI-Powered Development Workflow

A strategic guide for leveraging your AI subscriptions optimally throughout the development lifecycle.

---

## Your AI Arsenal

| Subscription | Primary Tool | Best For |
|-------------|--------------|----------|
| **Claude Max** | Claude Code CLI | Implementation, multi-file editing, debugging |
| **Cursor Max** | Cursor IDE | In-flow coding, autocomplete, quick edits |
| **ChatGPT Plus** | ChatGPT web/app | Brainstorming, diagrams, visual explanations |
| **Gemini Pro** | Gemini web/app | Large context analysis (1M tokens), research |
| **Perplexity Pro** | Perplexity web/app | Real-time research, citations, documentation |

---

## Development Phases

### Phase 1: Research & Planning

**Before writing any code, gather information.**

| Task | Tool | Why |
|------|------|-----|
| Tech stack research | **Perplexity Pro** | Real-time docs, citations, current best practices |
| Library comparisons | **Perplexity Pro** | Up-to-date benchmarks, community sentiment |
| Architecture brainstorm | **ChatGPT Plus** | Visual diagrams, flowcharts, sequence diagrams |
| Analyze reference repos | **Gemini Pro** | 1M token context fits entire codebases |
| Understanding unfamiliar concepts | **ChatGPT Plus** | Clear explanations with visuals |

**In Claude Code:**
```bash
# Compare AI opinions on architecture
/compare should I use microservices or monolith for this project?

# Quick research with your configured models
/gemini explain the trade-offs between REST and GraphQL
```

---

### Phase 2: Architecture & Design

**Design your system before implementation.**

| Task | Tool | Why |
|------|------|-----|
| System architecture | `@architect` (Claude Code) | Uses Opus, best for complex design |
| Database schema | `@database-expert` | Specialized knowledge |
| API design | `@backend-expert` | RESTful patterns, security |
| Visual diagrams | **ChatGPT Plus** | Generate architecture diagrams |
| Validate decisions | `/compare` | Multiple model perspectives |

**In Claude Code:**
```bash
# Design with the architect agent (uses Opus)
@architect design a scalable auth system for my SaaS app

# Get multiple perspectives on key decisions
/compare what's the best database for a high-write workload?
```

---

### Phase 3: Active Development

**This is where Claude Code and Cursor shine.**

#### Use Cursor When:
- Writing new code with autocomplete
- Making quick inline edits
- Tab-completing boilerplate
- Staying in IDE flow

#### Use Claude Code CLI When:
- Multi-file refactoring
- Complex debugging
- Agentic tasks (search → edit → test)
- Git workflows
- Security reviews

**Workflow Pattern:**
```
1. Open project in Cursor
2. Use Cursor for typing code (tab completion)
3. Switch to Claude Code terminal for complex operations
4. Use specialized agents for domain tasks
```

**In Claude Code:**
```bash
# Frontend work
@frontend-expert build a responsive dashboard component

# Backend work
@backend-expert implement JWT authentication middleware

# Quick questions while coding
/gpt4o how do I handle race conditions in React useEffect?

# Performance-critical code
@performance-optimizer optimize this database query
```

---

### Phase 4: Testing & Quality

**Ensure code quality before commit.**

| Task | Tool | Command |
|------|------|---------|
| Write tests | Claude Code | `@test-writer` |
| Code review | Claude Code | `@code-reviewer` |
| Security audit | Claude Code | `@security-auditor` or `/security-check` |
| Performance check | Claude Code | `@performance-optimizer` |

**Pre-commit checklist:**
```bash
# 1. Review changes
/git-review

# 2. Security scan
/security-check

# 3. If all good, commit
/git-quick
```

---

### Phase 5: Debugging

**When things break.**

| Scenario | Tool | Why |
|----------|------|-----|
| Bug in your code | `@debugger` | Systematic analysis with codebase context |
| Unknown error message | **Perplexity Pro** | Search for solutions with citations |
| Complex logic issue | `/o1` | Advanced reasoning model |
| Need multiple opinions | `/compare` | Different debugging approaches |

**In Claude Code:**
```bash
# Systematic debugging
@debugger this function returns null unexpectedly

# Complex algorithmic issues
/o1 why is this recursive function causing a stack overflow?

# Quick error lookup
/deepseek what does "ECONNREFUSED" mean in Node.js?
```

---

## Quick Decision Matrix

### Which Model for What?

| Question Type | Best Choice | Claude Code Command |
|---------------|-------------|---------------------|
| Quick coding question | GPT-4o | `/gpt4o` |
| Complex reasoning | Claude Opus | `/opus` |
| Math/logic puzzles | OpenAI o1 | `/o1` |
| Budget-friendly | DeepSeek | `/deepseek` |
| Need citations | Perplexity* | Use web app |
| Visual explanation | ChatGPT Plus | Use web app |
| Huge codebase analysis | Gemini Pro | Use web app |
| Important decision | Multiple | `/compare` |

*Consider adding `/perplexity` command (see Commands section)

---

### Which Tool for What?

| Task | Cursor | Claude Code | Web Apps |
|------|--------|-------------|----------|
| Writing new code | ★★★ | ★★ | - |
| Autocomplete | ★★★ | - | - |
| Multi-file edits | ★ | ★★★ | - |
| Complex debugging | ★ | ★★★ | - |
| Git workflows | - | ★★★ | - |
| Code review | ★ | ★★★ | - |
| Research | - | ★ | ★★★ |
| Brainstorming | - | ★ | ★★★ |
| Diagrams | - | - | ★★★ |

---

## Daily Workflow Template

```
┌─────────────────────────────────────────────────────────────┐
│  MORNING: Planning                                          │
├─────────────────────────────────────────────────────────────┤
│  • Perplexity → Research any unknowns                       │
│  • ChatGPT → Sketch architecture/diagrams                   │
│  • Claude Code → @architect for system design               │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  CODING: Implementation                                     │
├─────────────────────────────────────────────────────────────┤
│  • Cursor → Write code in flow (autocomplete)               │
│  • Claude Code → Complex multi-file operations              │
│  • Claude Code → @frontend-expert, @backend-expert          │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  STUCK: Problem Solving                                     │
├─────────────────────────────────────────────────────────────┤
│  • Claude Code → @debugger for systematic analysis          │
│  • Perplexity → Error messages, solutions with citations    │
│  • Claude Code → /o1 for complex logic problems             │
│  • Gemini → Paste large context for analysis                │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  END OF DAY: Review                                         │
├─────────────────────────────────────────────────────────────┤
│  • Claude Code → /git-review                                │
│  • Claude Code → /security-check                            │
│  • Claude Code → @test-writer if needed                     │
│  • Claude Code → /git-quick or /pr                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Anti-Patterns to Avoid

| Don't Do This | Do This Instead |
|---------------|-----------------|
| Use ChatGPT for implementation | Use Claude Code (has codebase context) |
| Use Claude Code for autocomplete | Use Cursor (faster, in-flow) |
| Guess at documentation | Use Perplexity (gets current info) |
| Ask same question to multiple tools | Use `/compare` in Claude Code |
| Use expensive models for simple tasks | Use `/gpt35` or `/deepseek` |
| Switch tools mid-task | Complete task in one tool when possible |

---

## Feature Development Playbook

### Small Feature (< 1 day)

```bash
# 1. Quick design
/gpt4o what's the best approach for [feature]?

# 2. Implement in Cursor + Claude Code
# Use Cursor for typing, Claude Code for complex parts

# 3. Review and commit
/git-review
/git-quick
```

### Medium Feature (1-3 days)

```bash
# Day 1: Design
@architect design [feature] considering our current architecture
/compare [key technical decision]

# Day 1-2: Implement
@backend-expert implement [backend portion]
@frontend-expert implement [frontend portion]

# Day 2-3: Test and review
@test-writer create comprehensive tests
@code-reviewer review all changes
/security-check

# Day 3: Ship
/pr
```

### Large Feature (1+ weeks)

```bash
# Research phase (use web apps)
# - Perplexity for technical research
# - ChatGPT for architecture diagrams
# - Gemini for analyzing similar codebases

# Design phase
@architect comprehensive design document
/compare [all major technical decisions]

# Implementation phase (iterate)
# - Break into subtasks
# - Use Cursor + Claude Code in tandem
# - Review each component with @code-reviewer

# Final review
@security-auditor full security audit
@test-writer ensure test coverage
/git-review
/pr
```

---

## Command Quick Reference

### Models (from Claude Code)

| Command | Model | Use Case |
|---------|-------|----------|
| `/gpt4o` | GPT-4o | Fast, everyday questions |
| `/gpt4` | GPT-4 | Complex reasoning |
| `/gpt35` | GPT-3.5 | Simple, budget-friendly |
| `/o1` | o1-preview | Math, logic, algorithms |
| `/opus` | Claude Opus 4 | Long docs, complex tasks |
| `/gemini` | Gemini Pro 1.5 | Large context |
| `/llama` | Llama 3.1 405B | Open source |
| `/deepseek` | DeepSeek V3 | Budget + good reasoning |
| `/mistral` | Mistral Large | European AI |
| `/compare` | Multiple | Important decisions |
| `/query [id]` | Any OpenRouter | Custom model |

### Agents (from Claude Code)

| Agent | Domain |
|-------|--------|
| `@architect` | System design (uses Opus) |
| `@code-reviewer` | Code quality |
| `@security-auditor` | Security |
| `@debugger` | Bug hunting |
| `@test-writer` | Testing |
| `@frontend-expert` | React/UI |
| `@backend-expert` | APIs/Server |
| `@database-expert` | SQL/NoSQL |
| `@devops-expert` | Infrastructure |
| `@performance-optimizer` | Speed |
| `@docs-writer` | Documentation |

### Workflows (from Claude Code)

| Command | Action |
|---------|--------|
| `/git-quick` | Stage → Commit → Push |
| `/git-review` | Security-aware review |
| `/pr` | Create GitHub PR |
| `/security-check` | Full security scan |
| `/ask [q]` | Quick Q&A |
| `/models` | List all models |
| `/agents` | List all agents |

---

## Tips for Maximum Efficiency

1. **Stay in one tool per task** - Context switching is expensive
2. **Use Cursor for flow** - Don't interrupt typing with Claude Code
3. **Use Claude Code for depth** - Complex operations need full context
4. **Use web apps for research** - They're optimized for exploration
5. **Use `/compare` for decisions** - Multiple perspectives on important choices
6. **Match model to task** - Don't use Opus for simple questions
7. **Leverage agents** - They're specialists in their domains
8. **Run `/security-check` often** - Before every commit ideally

---

## See Also

- [COMMANDS_REFERENCE.md](COMMANDS_REFERENCE.md) - Detailed command documentation
- [AGENTS_GUIDE.md](AGENTS_GUIDE.md) - Deep dive on agents
- [MODEL_USAGE.md](MODEL_USAGE.md) - API key configuration
- [QUICK_START.md](QUICK_START.md) - Initial setup guide
