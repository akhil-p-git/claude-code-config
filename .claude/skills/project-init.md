---
name: project-init
description: Initialize a new project with proper structure, .gitignore, environment setup, and configuration. Use when user wants to start a new project, create project structure, or set up a new codebase.
allowed-tools:
  - Bash
  - Write
  - Read
  - Glob
model: claude-sonnet-4-5-20250929
---

# Project Initialization

I'll help you set up a new project with best practices.

## 1. Project Structure

Based on your project type, I'll create the appropriate structure:

### Full-Stack (React + Node.js)
```
project/
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── pages/
│   │   ├── services/
│   │   └── types/
│   ├── package.json
│   └── tsconfig.json
├── backend/
│   ├── src/
│   │   ├── routes/
│   │   ├── controllers/
│   │   ├── services/
│   │   ├── models/
│   │   └── middleware/
│   ├── package.json
│   └── tsconfig.json
├── shared/
│   └── types/
├── .env.example
├── .gitignore
└── README.md
```

### Python Project
```
project/
├── src/
│   └── mypackage/
│       ├── __init__.py
│       ├── models/
│       ├── services/
│       └── utils/
├── tests/
├── .env.example
├── .gitignore
├── pyproject.toml
└── README.md
```

## 2. Essential Files

### .gitignore
Includes all critical entries:
- Environment files (`.env`, `.env.*`)
- Dependencies (`node_modules/`, `__pycache__/`)
- IDE files (`.idea/`, `.vscode/`)
- Secrets (`*.key`, `*.pem`, `secrets/`)
- Task management (`.taskmaster/`)

### .env.example
Template with all required environment variables (no real values).

### README.md
- Project description
- Prerequisites
- Installation instructions
- Running the project
- Environment setup

## 3. Configuration

### TypeScript Projects
- `tsconfig.json` with strict mode
- ESLint + Prettier configuration

### Python Projects
- `pyproject.toml` with dependencies
- Black + Ruff configuration

## 4. Git Setup

- Initialize git repository
- Create initial commit
- Set up branch protection recommendations

---

What type of project would you like to create?
