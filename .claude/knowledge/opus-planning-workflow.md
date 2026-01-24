# Opus Planning Workflow

> Guide for using Claude Opus for strategic planning and Sonnet for execution.

---

## The Two-Phase Approach

Use **Opus mode** for planning complex features and **Sonnet mode** for implementation. This separation provides:

1. **Strategic thinking** - Opus excels at architectural decisions
2. **Cost efficiency** - Sonnet is faster and cheaper for execution
3. **Clear separation** - Plan once, execute cleanly
4. **Parallel execution** - Once planned, multiple agents can work simultaneously

---

## When to Use Opus for Planning

### Always Use Opus For:
- **System architecture** - Major architectural decisions
- **Complex features** - Multi-component implementations
- **Refactoring strategies** - Large-scale code reorganization
- **Technical debt resolution** - Prioritizing and planning cleanup
- **API design** - Designing new APIs or major changes
- **Database schema design** - Data modeling decisions
- **Migration planning** - Framework/library upgrades
- **Security architecture** - Authentication, authorization design

### Use Sonnet For:
- **Direct implementation** - Following an established plan
- **Bug fixes** - Clear, isolated issues
- **Simple features** - Well-defined, small scope
- **Code reviews** - Analysis and feedback
- **Documentation** - Writing docs from existing code
- **Test writing** - Creating tests for existing code

---

## Workflow Steps

### 1. Start Planning (Opus Mode)

```
/model opus
```

Or use the `@architect` agent which automatically uses Opus:

```
@architect design a user authentication system with OAuth2,
session management, and role-based access control
```

### 2. Capture the Plan

The plan should include:
- **Overview** - What we're building and why
- **Components** - Major parts of the system
- **File structure** - Where code will live
- **Dependencies** - Required packages
- **Implementation order** - Sequence of steps
- **Edge cases** - Error handling, validation
- **Testing strategy** - What to test

### 3. Save to CLAUDE.md or Knowledge File

For project-specific plans:
```markdown
# Project: [Feature Name] Implementation Plan

## Overview
[Brief description]

## Components
1. [Component A] - [purpose]
2. [Component B] - [purpose]

## Implementation Steps
1. [ ] Step 1
2. [ ] Step 2
3. [ ] Step 3

## Files to Create/Modify
- `src/auth/oauth.ts` - OAuth2 implementation
- `src/middleware/auth.ts` - Auth middleware
- `src/types/auth.ts` - Type definitions
```

### 4. Switch to Sonnet for Execution

```
/model sonnet
```

Or start a new session - the plan in CLAUDE.md will load automatically.

### 5. Execute with Multiple Agents

With the plan captured, spawn specialized agents in parallel:

```
@backend-expert implement the OAuth2 flow from the plan
@test-writer create tests for the auth middleware
@docs-writer document the authentication API
```

---

## Example: Full Workflow

### Phase 1: Planning with Opus

**User:** I need to add real-time notifications to our app

**Claude (Opus):**
```markdown
# Real-time Notifications Implementation Plan

## Architecture Decision
WebSockets via Socket.io for real-time delivery with Redis pub/sub
for horizontal scaling.

## Components
1. **NotificationService** - Business logic for creating/managing notifications
2. **WebSocketServer** - Socket.io server setup
3. **NotificationChannel** - Redis pub/sub integration
4. **NotificationStore** - Persistent storage (PostgreSQL)
5. **NotificationUI** - React components for display

## Implementation Order
1. Database schema and migrations
2. NotificationService with CRUD operations
3. WebSocket server setup
4. Redis pub/sub integration
5. React notification components
6. Integration testing

## Files to Create
- `backend/src/services/notification.ts`
- `backend/src/websocket/server.ts`
- `backend/src/websocket/channels/notification.ts`
- `frontend/src/components/NotificationBell.tsx`
- `frontend/src/hooks/useNotifications.ts`
```

### Phase 2: Execution with Sonnet

**User:** Execute the notification plan

**Claude (Sonnet):** *Reads plan from CLAUDE.md*

Creates todo list:
1. Create database schema
2. Implement NotificationService
3. Set up WebSocket server
4. Add Redis pub/sub
5. Build React components
6. Write tests

Spawns agents:
```
@backend-expert - Implements backend services
@frontend-expert - Builds React components
@database-expert - Creates migrations
@test-writer - Writes integration tests
```

---

## Tips for Effective Planning

### In Opus Mode:
1. **Ask clarifying questions** before designing
2. **Consider trade-offs** and document alternatives
3. **Think about edge cases** early
4. **Plan for testing** as part of the design
5. **Keep plans actionable** - specific files and steps

### In Sonnet Mode:
1. **Follow the plan** - resist scope creep
2. **Update plan if blocked** - document deviations
3. **Complete incrementally** - one step at a time
4. **Test as you go** - don't defer testing

---

## Model Selection Reference

| Task Type | Model | Reason |
|-----------|-------|--------|
| Architecture design | Opus | Complex reasoning |
| API design | Opus | Trade-off analysis |
| Code implementation | Sonnet | Speed, cost |
| Bug fixes | Sonnet | Direct execution |
| Code review | Sonnet | Analysis |
| Complex debugging | Opus | Deep reasoning |
| Refactoring plan | Opus | Strategy |
| Refactoring execution | Sonnet | Implementation |
| Documentation | Sonnet | Straightforward |
| Security audit | Opus | Thorough analysis |

---

## Quick Reference

```bash
# Switch to Opus for planning
/model opus

# Design with @architect (uses Opus by default)
@architect design [feature]

# Switch to Sonnet for execution
/model sonnet

# Execute with specialized agents
@backend-expert implement [part of plan]
@frontend-expert build [component]
@test-writer test [module]
```
