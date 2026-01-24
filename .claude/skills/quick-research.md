---
name: quick-research
description: Quick research and question answering with project context. Use when user asks a question, wants information, or needs help understanding something about their codebase or a technical topic.
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - WebFetch
  - WebSearch
model: claude-sonnet-4-5-20250929
---

# Quick Research

I'll help answer your question using both project context and external resources.

## Your Question

$ARGUMENTS

---

## Research Approach

### 1. Project Context
First, I'll search your codebase for relevant information:
- Related files and code
- Existing implementations
- Configuration and setup

### 2. External Resources
If needed, I'll search for:
- Documentation
- Best practices
- Code examples
- Solutions to common problems

### 3. Synthesized Answer
I'll provide:
- Direct answer to your question
- Relevant code examples from your project
- External references if applicable
- Recommended next steps

---

## Response

Based on my research, here's what I found...
