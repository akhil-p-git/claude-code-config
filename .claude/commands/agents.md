---
description: "List all available specialized agents"
allowed-tools: ["Bash"]
model: "claude-sonnet-4-5-20250929"
---

# Available Specialized Agents

You have access to 11 expert agents, each specialized in a specific domain:

## 🔍 Code Quality

**@code-reviewer**
- Reviews code for bugs, best practices, and maintainability
- Prioritizes issues (Critical → Low)
- Provides concrete improvement suggestions

**@security-auditor**
- Scans for OWASP Top 10 vulnerabilities
- Checks for hardcoded secrets
- Reviews authentication/authorization

**@debugger**
- Systematic bug hunting
- Root cause analysis
- Provides fixes and prevention tips

## ⚡ Performance & Testing

**@performance-optimizer**
- Profiles and optimizes code
- Frontend and backend optimization
- Measures impact of changes

**@test-writer**
- Writes comprehensive test suites
- Unit, integration, and E2E tests
- Aims for 80%+ coverage

## 💻 Domain Experts

**@frontend-expert**
- React, TypeScript, modern CSS
- Component architecture
- Performance and accessibility

**@backend-expert**
- APIs, databases, authentication
- Node.js/Express, Python/FastAPI
- Security and performance

**@database-expert**
- Schema design and optimization
- Query performance tuning
- SQL and NoSQL expertise

**@devops-expert**
- Infrastructure and CI/CD
- Docker, Kubernetes, cloud platforms
- Monitoring and scaling

## 🏗️ Architecture & Documentation

**@architect** ⭐ (uses Opus)
- System design and architecture
- Scalability planning
- Technology choices and trade-offs

**@docs-writer**
- Technical documentation
- README files, API docs
- Clear, maintainable documentation

---

## How to Use Agents

**In Claude Code:**

```bash
# Start a conversation with an agent
@code-reviewer

# Then ask your question
Review the authentication module in src/auth/

# Or combine in one message
@security-auditor scan the entire codebase for vulnerabilities
```

**List agents:**
! ls ~/.claude/agents/ | sed 's/.md$//' | sed 's/^/@/'

---

## Pro Tips

- **@architect** uses Claude Opus (more powerful, best for complex design)
- Chain agents: "@code-reviewer then @test-writer" to review and add tests
- Agents have specialized tools and knowledge for their domain
- All agents are configured in `~/.claude/agents/`

Choose the right expert for your task!
