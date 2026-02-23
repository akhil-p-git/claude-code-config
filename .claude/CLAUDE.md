# Global Coding Standards & Guidelines

## Agent & Skill Automation (CRITICAL)

### Automatic Agent Selection
ALWAYS automatically spawn the appropriate agent(s) based on the task. DO NOT ask permission - just use them:

| Task Type | Agent(s) to Spawn |
|-----------|-------------------|
| Code cleanup, refactoring | `@refactorer` |
| Bug investigation | `@debugger` |
| Security review | `@security-auditor` |
| Performance issues | `@performance-optimizer` |
| API design | `@api-designer` |
| Database work | `@database-expert` |
| System design | `@architect` |
| Writing tests | `@test-writer` |
| Code review | `@code-reviewer` |
| Documentation | `@docs-writer` |
| React/UI work | `@frontend-expert` |
| Node.js/API work | `@backend-expert` |
| Full-stack features | `@fullstack-developer` |
| DevOps/CI/CD | `@devops-expert` |
| Accessibility | `@accessibility-expert` |
| Data pipelines | `@data-engineer` |
| Mobile dev | `@mobile-expert` |
| AI/ML integration | `@ai-engineer` |
| Monorepo setup | `@monorepo-expert` |
| UX issues | `@ux-reviewer` |
| Regex help | `@regex-expert` |
| Git problems | `@git-expert` |
| Migrations/upgrades | `@migration-expert` |
| Game development | `@game-developer` |
| Tech debt assessment | `@tech-debt-analyzer` |
| Production incidents | `@incident-responder` |
| Codebase exploration | Explore agent (built-in) |

### Automatic Parallel Agents (Swarms)
Spawn multiple agents IN PARALLEL when the task benefits from multiple perspectives:

**Always swarm for:**
- "Review this code/PR" → `@code-reviewer` + `@security-auditor` + `@performance-optimizer`
- "Audit this project" → `@security-auditor` + `@accessibility-expert` + `@tech-debt-analyzer`
- "Check code quality" → `@code-reviewer` + `@refactorer` + `@test-writer`
- "Prepare for production" → `@security-auditor` + `@performance-optimizer` + `@devops-expert`
- "Review game code" → `@game-developer` + `@performance-optimizer` + `@code-reviewer`
- "Full-stack feature" → `@fullstack-developer` + `@test-writer`

**Swarm when user says:** "thoroughly", "comprehensive", "check everything", "multiple perspectives", "in parallel"

### Automatic Skill Invocation
Use skills automatically when the task matches - DO NOT ask:

| Task | Skill |
|------|-------|
| Quick git commit workflow | `git-quick` |
| Review git changes | `git-review` |
| Create GitHub PR | `pr` |
| Security scan project | `security-check` |
| Organize project structure | `split-project` |
| Quick research / Q&A | `ask` |
| Compare AI model answers | `compare` |
| Web-connected research | `perplexity` |
| Query DeepSeek V3 | `deepseek` |
| Query Claude Opus 4 | `opus` |
| Query GPT-4o | `gpt4o` |
| Query OpenAI o1 | `o1` |
| Query any model by ID | `query` |
| List available models | `models` |

### Behavior Rules
1. **Don't ask** - Just spawn agents/skills when appropriate
2. **Prefer parallel** - When 2+ agents are relevant, run them simultaneously
3. **Combine results** - Synthesize multi-agent output into coherent response
4. **Use Explore freely** - For any codebase understanding task
5. **Chain when needed** - e.g., `@debugger` finds issue → `@refactorer` fixes it

---

## Git Operations (CRITICAL)

**ALWAYS use these commands to bypass Claude Code's restricted GITHUB_TOKEN:**

```bash
GIT_ASKPASS="" GITHUB_TOKEN="" git fetch origin
GIT_ASKPASS="" GITHUB_TOKEN="" git push origin <branch>
GIT_ASKPASS="" GITHUB_TOKEN="" git pull origin <branch>
```

---

## Project Architecture

- **Frontend:** `/frontend`, `/client`, or `/app`
- **Backend:** `/backend`, `/server`, or `/api`
- **Shared:** `/shared` or `/common`
- Never mix frontend and backend in the same directory

---

## Language Standards (Reference Files)

Detailed standards are in knowledge files - loaded automatically when relevant:

| Language/Area | Reference File |
|---------------|----------------|
| JavaScript/TypeScript | `.claude/knowledge/javascript-typescript-standards.md` |
| React | `.claude/knowledge/react-best-practices.md` |
| Node.js/Backend | `.claude/knowledge/nodejs-backend-standards.md` |
| Python | `.claude/knowledge/python-standards.md` |
| C | `.claude/knowledge/c-standards.md` |
| Security | `.claude/knowledge/security-standards.md` |
| Testing | `.claude/knowledge/testing-standards.md` |
| Game Development | `.claude/agents/game-developer.md` |
| Opus Planning | `.claude/knowledge/opus-planning-workflow.md` |

### Quick Reference

**Naming:**
- JS/TS: `camelCase` vars/functions, `PascalCase` classes/components, `UPPER_SNAKE_CASE` constants
- Python: `snake_case` vars/functions, `PascalCase` classes
- C: `snake_case` vars/functions, `UPPER_SNAKE_CASE` macros

**Key Rules:**
- TypeScript strict mode for all TS projects
- Python type hints on all functions
- C: always check malloc, always free
- 80%+ test coverage
- Never commit secrets

---

## Security (CRITICAL)

> Full reference: `.claude/knowledge/security-standards.md`

**Never commit:** `.env`, `*.key`, `*.pem`, `secrets/`, `.taskmaster/`

**Always:**
- Validate all user input
- Use parameterized queries (no SQL injection)
- Run `npm audit` or `pip-audit` before commits

---

## Performance (React)

> Full reference: `.claude/knowledge/react-best-practices.md`

**CRITICAL:**
- `Promise.all()` for independent async operations
- `next/dynamic` for heavy components
- Avoid barrel imports

**HIGH:**
- `React.cache()` for server deduplication
- SWR/React Query for client deduplication

---

## Commit Messages

Format: `type(scope): description`

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Example: `feat(auth): add OAuth2 login support`

---

## Code Review Checklist

- [ ] No secrets in code
- [ ] `.env` and `.taskmaster/` in .gitignore
- [ ] Tests pass with 80%+ coverage
- [ ] No console.log statements
- [ ] Error handling implemented
- [ ] Frontend/backend separated

---

**Remember:** These are guidelines. Use judgment based on context, but default to these standards when in doubt.
