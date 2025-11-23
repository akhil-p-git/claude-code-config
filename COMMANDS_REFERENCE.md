# Complete Commands Reference

Quick reference for all custom commands, AI models, and specialized agents.

---

## 🎯 Quick Access

- **Git Workflows**: `/git-quick`, `/git-review`, `/pr`
- **Security**: `/security-check`
- **Q&A**: `/ask [question]`
- **Project Structure**: `/split-project`
- **AI Models**: `/gpt4`, `/opus`, `/gemini`, `/compare`, `/models`
- **Agents**: `/agents`, then `@agent-name`

---

## 📋 Table of Contents

1. [Git & GitHub Commands](#git--github-commands)
2. [AI Model Commands](#ai-model-commands)
3. [Utility Commands](#utility-commands)
4. [Specialized Agents](#specialized-agents)
5. [Quick Workflows](#quick-workflows)

---

## Git & GitHub Commands

### `/git-quick`
**Quick git workflow: status → stage → commit → push**

```bash
/git-quick
```

**What it does:**
1. Shows git status and diff
2. Helps you stage files
3. Creates a meaningful commit message
4. Pushes to remote

**When to use:**
- Quick commits during development
- You want guided git workflow
- Ensure you don't miss changes

---

### `/git-review`
**Comprehensive code review with security checks**

```bash
/git-review
```

**What it does:**
1. Shows git status and full diff
2. Scans for potential secrets (API keys, passwords)
3. Reviews code quality
4. Validates .gitignore entries
5. Recommends commit message

**When to use:**
- Before committing important changes
- Before creating a PR
- Security-sensitive code
- Want thorough review

---

### `/pr`
**Create GitHub pull request with auto-generated description**

```bash
/pr
```

**What it does:**
1. Shows current branch and changes
2. Analyzes all commits since divergence
3. Generates PR title and description
4. Runs pre-PR checklist
5. Creates PR using `gh` CLI

**When to use:**
- Ready to create a pull request
- Want well-formatted PR description
- Need PR checklist validation

**Requirements:**
- `gh` CLI installed
- Authenticated with GitHub

---

## AI Model Commands

### OpenAI Models

#### `/gpt4`
**Query GPT-4 (most capable OpenAI model)**

```bash
/gpt4 explain async/await in JavaScript
```

**Model:** `gpt-4`
**Best for:** Complex reasoning, coding help, general questions

---

#### `/gpt4o`
**Query GPT-4o (latest, fastest)**

```bash
/gpt4o what's the best way to optimize React components?
```

**Model:** `gpt-4o`
**Best for:** Fast responses, general tasks, everyday questions

---

#### `/gpt35`
**Query GPT-3.5 Turbo (fast and cost-effective)**

```bash
/gpt35 write a Python function to sort a list
```

**Model:** `gpt-3.5-turbo`
**Best for:** Simple questions, quick answers, budget-conscious usage

---

#### `/o1`
**Query OpenAI o1 (advanced reasoning)**

```bash
/o1 solve this complex algorithm problem
```

**Model:** `o1-preview`
**Best for:** Math, logic puzzles, complex problem-solving
**Note:** Slower but more thorough reasoning

---

### Claude Models (via OpenRouter)

#### `/opus`
**Query Claude Opus 4 (most capable Claude)**

```bash
/opus write a comprehensive technical architecture document
```

**Model:** `anthropic/claude-opus-4-20250514`
**Best for:** Long documents, complex reasoning, creative writing

---

### Google Models

#### `/gemini`
**Query Google Gemini Pro 1.5**

```bash
/gemini explain quantum computing in simple terms
```

**Model:** `google/gemini-pro-1.5`
**Best for:** Large context, Google-related tasks, research

---

### Open Source Models

#### `/llama`
**Query Meta Llama 3.1 405B**

```bash
/llama help me refactor this Python code
```

**Model:** `meta-llama/llama-3.1-405b-instruct`
**Best for:** Open source preference, large model capabilities

---

#### `/mistral`
**Query Mistral Large**

```bash
/mistral optimize this database query
```

**Model:** `mistralai/mistral-large`
**Best for:** European AI preference, strong performance

---

#### `/deepseek`
**Query DeepSeek V3 (cost-effective reasoning)**

```bash
/deepseek debug this algorithm
```

**Model:** `deepseek/deepseek-chat`
**Best for:** Budget-friendly but powerful, good reasoning

---

### Special Model Commands

#### `/compare`
**Ask multiple models simultaneously**

```bash
/compare what's the best database for a startup?
```

**Queries:** GPT-4o, Claude Opus, Gemini Pro
**Best for:** Important decisions, multiple perspectives, comparing approaches

**Output:** Shows all three responses side-by-side

---

#### `/models`
**List all available AI models**

```bash
/models
```

**What it does:**
- Lists OpenAI models
- Lists top OpenRouter models
- Fetches live model list from OpenRouter
- Shows usage instructions

---

#### `/query`
**Query any OpenRouter model by ID**

```bash
/query anthropic/claude-3.5-sonnet explain recursion
/query google/gemini-flash-1.5 quick question about APIs
```

**Syntax:** `/query [model-id] [your question]`

**Popular model IDs:**
- `anthropic/claude-3.5-sonnet` - Claude Sonnet
- `google/gemini-flash-1.5` - Fast Gemini
- `meta-llama/llama-3.1-70b-instruct` - Llama 70B
- `openai/gpt-4-turbo` - GPT-4 Turbo via OpenRouter

---

## Utility Commands

### `/ask`
**Quick research and Q&A with project context**

```bash
/ask how do I implement JWT authentication?
/ask what's the difference between REST and GraphQL?
```

**What it does:**
1. Searches your codebase for relevant context
2. Can use web search if needed
3. Provides clear, actionable answers
4. Understands your project structure

**Best for:**
- Quick questions during development
- Learning new concepts
- Understanding your codebase

---

### `/security-check`
**Comprehensive security audit**

```bash
/security-check
```

**What it does:**
1. Validates .gitignore (checks for .env, .taskmaster/, etc.)
2. Scans for exposed secrets (API keys, tokens)
3. Checks environment files
4. Runs dependency security audit
5. Scans git history for accidentally committed secrets

**Checks for:**
- Hardcoded API keys
- Database credentials
- JWT tokens
- Private keys (.pem, .key files)
- Vulnerable dependencies

**When to use:**
- Before every commit (best practice)
- Before production deployment
- After cloning a project
- Regular security audits

---

### `/split-project`
**Analyze and organize frontend/backend structure**

```bash
/split-project
```

**What it does:**
1. Analyzes current project structure
2. Identifies frontend vs backend files
3. Suggests proper organization
4. Can help migrate to clean structure

**Recommends:**
```
project/
├── frontend/  (React, UI)
├── backend/   (API, server)
├── shared/    (common code)
```

**When to use:**
- Project structure is messy
- Want to separate concerns
- Starting new project
- Refactoring monolith

---

## Specialized Agents

**Agents are AI experts in specific domains. Use them with `@agent-name`**

### View All Agents

```bash
/agents
```

---

### Code Quality Agents

#### `@code-reviewer`
**Expert code reviewer**

```bash
@code-reviewer review src/auth/login.ts
@code-reviewer check this entire module for issues
```

**Reviews for:**
- Bugs and logic errors
- Best practices
- Performance issues
- Security vulnerabilities
- Maintainability
- Test coverage

**Output:**
- Critical issues (must fix)
- Improvements (nice-to-have)
- Positive feedback
- Code examples

---

#### `@security-auditor`
**Security vulnerability expert**

```bash
@security-auditor scan the API for vulnerabilities
@security-auditor check src/auth/ for security issues
```

**Checks for:**
- OWASP Top 10 vulnerabilities
- SQL injection, XSS, CSRF
- Hardcoded secrets
- Authentication/authorization flaws
- Insecure dependencies

**Output:**
- Critical vulnerabilities
- Remediation steps
- Prevention tips

---

#### `@debugger`
**Expert bug hunter**

```bash
@debugger this function crashes with null inputs
@debugger why is this async function hanging?
```

**Approach:**
- Systematic debugging
- Root cause analysis
- Stack trace analysis
- Reproduces bugs

**Output:**
- Root cause explanation
- The fix
- Prevention strategy
- Test to verify fix

---

### Performance & Testing

#### `@performance-optimizer`
**Performance optimization expert**

```bash
@performance-optimizer this page loads slowly
@performance-optimizer optimize this database query
```

**Optimizes:**
- Frontend (bundle size, rendering)
- Backend (queries, caching)
- Algorithms (complexity)
- Resource usage

**Output:**
- Current performance baseline
- Bottlenecks identified
- Specific optimizations
- Expected impact
- Verification method

---

#### `@test-writer`
**Testing expert**

```bash
@test-writer create tests for src/utils/validator.ts
@test-writer I need comprehensive test coverage
```

**Writes:**
- Unit tests
- Integration tests
- Edge cases
- Error scenarios

**Output:**
- Test plan
- Complete test code
- Coverage report
- Setup instructions

---

### Domain Experts

#### `@frontend-expert`
**React and UI specialist**

```bash
@frontend-expert build a responsive navigation menu
@frontend-expert optimize this React component
```

**Expertise:**
- React (hooks, components)
- TypeScript
- Modern CSS
- State management
- Performance
- Accessibility

---

#### `@backend-expert`
**API and backend specialist**

```bash
@backend-expert design a RESTful authentication API
@backend-expert implement rate limiting
```

**Expertise:**
- RESTful APIs, GraphQL
- Node.js/Express, Python/FastAPI
- Databases (SQL, NoSQL)
- Authentication/authorization
- Security

---

#### `@database-expert`
**Database specialist**

```bash
@database-expert design a schema for e-commerce
@database-expert why is this query slow?
```

**Expertise:**
- Schema design
- Query optimization
- Indexing strategies
- Migrations
- SQL and NoSQL

---

#### `@devops-expert`
**Infrastructure specialist**

```bash
@devops-expert set up CI/CD with GitHub Actions
@devops-expert create a Docker setup
```

**Expertise:**
- Docker, Kubernetes
- CI/CD pipelines
- Cloud platforms (AWS, GCP, Azure)
- Monitoring
- Infrastructure as Code

---

### Architecture & Documentation

#### `@architect` ⭐
**System design expert (uses Claude Opus)**

```bash
@architect design a scalable microservices architecture
@architect should I use SQL or NoSQL for this?
```

**Uses:** Claude Opus (most powerful model)

**Expertise:**
- System architecture
- Technology choices
- Scalability planning
- Trade-off analysis
- Migration strategies

**Output:**
- Architecture diagrams
- Component breakdown
- Technology recommendations
- Trade-offs
- Migration path

---

#### `@docs-writer`
**Technical documentation expert**

```bash
@docs-writer create a README for this project
@docs-writer document this API
```

**Creates:**
- README files
- API documentation
- Code comments
- Architecture docs
- User guides

---

## Quick Workflows

### Before Committing Code

```bash
# 1. Review your changes
/git-review

# 2. Run security check
/security-check

# 3. If all good, commit
/git-quick
```

---

### Before Creating PR

```bash
# 1. Code review
@code-reviewer review my changes

# 2. Security audit
@security-auditor scan for vulnerabilities

# 3. Check test coverage
@test-writer check if tests are needed

# 4. Create PR
/pr
```

---

### Building a New Feature

```bash
# 1. Design architecture
@architect design [feature description]

# 2. Implement backend
@backend-expert implement [feature]

# 3. Implement frontend
@frontend-expert build UI for [feature]

# 4. Add tests
@test-writer create comprehensive tests

# 5. Document
@docs-writer document [feature]

# 6. Review and commit
/git-review
/git-quick
```

---

### Debugging Performance

```bash
# 1. Identify issue
@debugger why is [component/function] slow?

# 2. Optimize
@performance-optimizer make [component] faster

# 3. Verify with tests
@test-writer ensure tests still pass

# 4. Commit
/git-quick
```

---

### Comparing AI Models

```bash
# Ask multiple models for different perspectives
/compare what's the best way to implement caching?

# Or ask specific models
/gpt4o quick implementation question
/opus detailed architecture question
/gemini research-heavy question
```

---

## Model Selection Guide

| Task | Recommended Model | Command |
|------|------------------|---------|
| Quick questions | GPT-4o | `/gpt4o` |
| Complex reasoning | GPT-4 or Opus | `/gpt4` or `/opus` |
| Math/logic | o1 | `/o1` |
| Long documents | Opus | `/opus` |
| Budget-friendly | GPT-3.5 or DeepSeek | `/gpt35` or `/deepseek` |
| Multiple perspectives | Compare | `/compare` |
| Open source | Llama | `/llama` |

---

## Agent Selection Guide

| Task | Recommended Agent |
|------|------------------|
| Code review | `@code-reviewer` |
| Security audit | `@security-auditor` |
| Bug fixing | `@debugger` |
| Performance | `@performance-optimizer` |
| Writing tests | `@test-writer` |
| React/UI work | `@frontend-expert` |
| APIs/backend | `@backend-expert` |
| Database work | `@database-expert` |
| Infrastructure | `@devops-expert` |
| System design | `@architect` (uses Opus) |
| Documentation | `@docs-writer` |

---

## Pro Tips

1. **Chain commands**: Use multiple agents/commands in sequence
2. **Security first**: Run `/security-check` before every commit
3. **Use `/compare`**: For important technical decisions
4. **@architect uses Opus**: Best for complex design questions
5. **Agents are specialists**: Use the right expert for each task
6. **`/models`**: Explore all available AI models
7. **Custom queries**: Use `/query` for any OpenRouter model

---

## Getting Help

```bash
# List all commands
/help

# List all agents
/agents

# List all AI models
/models

# View configuration
/config

# Check permissions
/permissions
```

---

## File Locations

- **Commands**: `~/.claude/commands/`
- **Agents**: `~/.claude/agents/`
- **Settings**: `~/.claude/settings.json`
- **Global rules**: `~/.claude/CLAUDE.md`
- **Dotfiles repo**: `~/my-dotfiles/`

---

All commands and agents are ready to use immediately! Just type `claude` to start.
