# Specialized AI Agents Guide

Your Claude Code setup now includes **11 specialized AI agents**, each an expert in a specific domain.

## What Are Agents?

Agents are specialized versions of Claude with:
- **Domain expertise** - Deep knowledge in specific areas
- **Custom instructions** - Tailored behavior for their role
- **Specific tools** - Access to tools they need
- **Different models** - Some use Opus for complex tasks

## Available Agents

### 🔍 Code Quality Agents

#### @code-reviewer
**When to use:** Before merging code, during PR reviews

**What it does:**
- Identifies bugs and logic errors
- Checks best practices and code quality
- Reviews performance implications
- Suggests concrete improvements
- Prioritizes issues by severity

**Example:**
```bash
@code-reviewer review src/auth/login.ts
```

#### @security-auditor
**When to use:** Security audits, before production deployments

**What it does:**
- Scans for OWASP Top 10 vulnerabilities
- Detects hardcoded secrets and credentials
- Reviews authentication/authorization logic
- Checks for SQL injection, XSS, CSRF
- Provides remediation steps

**Example:**
```bash
@security-auditor scan the entire API for vulnerabilities
```

#### @debugger
**When to use:** When you have a bug you can't figure out

**What it does:**
- Systematic debugging approach
- Root cause analysis
- Traces through stack traces
- Provides fix and prevention tips
- Thinks like a detective

**Example:**
```bash
@debugger this function crashes with large inputs
```

### ⚡ Performance & Testing

#### @performance-optimizer
**When to use:** App is slow, optimization needed

**What it does:**
- Profiles code to find bottlenecks
- Frontend optimization (bundle size, rendering)
- Backend optimization (queries, caching)
- Provides before/after measurements
- Considers trade-offs

**Example:**
```bash
@performance-optimizer this component re-renders too much
```

#### @test-writer
**When to use:** Need comprehensive test coverage

**What it does:**
- Writes unit, integration, and E2E tests
- Covers edge cases and error scenarios
- Follows testing best practices
- Aims for 80%+ coverage
- Tests behavior, not implementation

**Example:**
```bash
@test-writer create tests for src/utils/validation.ts
```

### 💻 Domain Experts

#### @frontend-expert
**When to use:** React, UI, or frontend challenges

**What it does:**
- React hooks and component architecture
- TypeScript best practices
- Modern CSS solutions
- State management (Context, Zustand, Redux)
- Performance and accessibility

**Example:**
```bash
@frontend-expert build a data table with sorting and filtering
```

#### @backend-expert
**When to use:** APIs, databases, server-side work

**What it does:**
- RESTful API design
- Database integration
- Authentication/authorization
- Node.js/Express or Python/FastAPI
- Security and performance

**Example:**
```bash
@backend-expert design an authentication system with JWT
```

#### @database-expert
**When to use:** Database design or query optimization

**What it does:**
- Schema design and normalization
- Query optimization (EXPLAIN analysis)
- Index strategy
- Migrations and data integrity
- SQL and NoSQL expertise

**Example:**
```bash
@database-expert optimize this slow query
```

#### @devops-expert
**When to use:** Infrastructure, deployment, CI/CD

**What it does:**
- Docker and Kubernetes
- CI/CD pipelines (GitHub Actions)
- Cloud platforms (AWS, GCP, Azure)
- Monitoring and scaling
- Infrastructure as Code

**Example:**
```bash
@devops-expert set up CI/CD with GitHub Actions
```

### 🏗️ Architecture & Documentation

#### @architect ⭐
**When to use:** System design, architecture decisions

**Uses Claude Opus** (most powerful model for complex reasoning)

**What it does:**
- High-level system architecture
- Technology choice recommendations
- Scalability planning
- Trade-off analysis
- Migration strategies

**Example:**
```bash
@architect design a microservices architecture for our e-commerce platform
```

#### @docs-writer
**When to use:** Need documentation

**What it does:**
- README files
- API documentation
- Code comments
- Architecture diagrams
- User guides

**Example:**
```bash
@docs-writer create a README for this project
```

---

## How to Use Agents

### Method 1: Direct Mention

```bash
# Start Claude Code
claude

# Mention the agent with @
@code-reviewer

# Then ask your question
Review the authentication module
```

### Method 2: Combined in One Message

```bash
claude

@security-auditor scan src/api/ for vulnerabilities
```

### Method 3: Chain Multiple Agents

```bash
# First review the code
@code-reviewer review src/auth/login.ts

# Then add tests
@test-writer create comprehensive tests for src/auth/login.ts

# Then check security
@security-auditor audit src/auth/login.ts
```

### Method 4: View All Agents

```bash
claude
/agents
```

---

## Workflow Examples

### Before Merging a PR

```bash
@code-reviewer review my changes
# Fix issues found
@security-auditor check for vulnerabilities
# Fix security issues
@test-writer add tests for uncovered code
# Add tests
Ready to merge!
```

### Building a New Feature

```bash
@architect design a user authentication system
# Get architecture
@backend-expert implement the backend API
# Build backend
@frontend-expert create the login UI
# Build frontend
@test-writer write comprehensive tests
# Add tests
@docs-writer document the authentication flow
# Document
```

### Debugging Performance Issues

```bash
@debugger why is this function slow?
# Identify the issue
@performance-optimizer optimize this code
# Apply optimizations
@test-writer ensure tests still pass
# Verify with tests
```

### Security Audit

```bash
@security-auditor full security audit
# Review findings
@code-reviewer check fixes don't break anything
# Implement fixes
@test-writer add security tests
# Prevent regression
```

---

## Pro Tips

1. **Use the right expert** - Each agent is optimized for its domain
2. **@architect uses Opus** - Most powerful for complex system design
3. **Chain agents** - Use multiple agents for comprehensive review
4. **Be specific** - "Review auth module" is better than "review code"
5. **Iterate** - Agents can follow up on their own suggestions
6. **Check /agents** - See all available agents anytime

## Customization

Agents are defined in `~/.claude/agents/`. You can:
- Edit existing agents (change instructions)
- Add new agents for your specific needs
- Change which model an agent uses
- Customize allowed tools

**Edit an agent:**
```bash
nano ~/.claude/agents/code-reviewer.md
```

**Create a new agent:**
```bash
nano ~/.claude/agents/my-custom-agent.md
```

Use this template:
```markdown
---
name: "My Agent Name"
description: "What this agent does"
model: "claude-sonnet-4-5-20250929"
allowedTools: ["Read", "Write", "Bash"]
---

You are an expert in [domain].

Your mission is to [goal].

[Instructions and guidelines]
```

---

## Quick Reference

| Agent | Use For | Model |
|-------|---------|-------|
| @code-reviewer | Code quality, bugs | Sonnet |
| @security-auditor | Vulnerabilities | Sonnet |
| @debugger | Bug hunting | Sonnet |
| @performance-optimizer | Speed optimization | Sonnet |
| @test-writer | Writing tests | Sonnet |
| @frontend-expert | React, UI work | Sonnet |
| @backend-expert | APIs, databases | Sonnet |
| @database-expert | Schema, queries | Sonnet |
| @devops-expert | Infrastructure | Sonnet |
| @architect | System design | **Opus** |
| @docs-writer | Documentation | Sonnet |

---

You now have a team of AI experts at your fingertips!
