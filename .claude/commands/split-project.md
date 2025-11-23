---
description: "Analyze and organize project into frontend/backend structure"
allowed-tools: ["Bash", "Read", "Write", "Glob", "Grep"]
model: "claude-sonnet-4-5-20250929"
---

# Project Structure Analysis

I'll help you organize your project with proper frontend/backend separation.

## Current Structure

! find . -maxdepth 3 -type d -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/.*" 2>/dev/null | head -50

! ls -la

## Analyzing Files

Let me identify:
- **Frontend files:** React components, UI code, client-side logic
- **Backend files:** API routes, server code, database models
- **Shared code:** Types, utilities, constants
- **Configuration:** Build tools, environment files

## Recommended Structure

Based on your project, I'll suggest:

```
project/
├── frontend/              # React app
│   ├── src/
│   │   ├── components/   # React components
│   │   ├── pages/        # Page components
│   │   ├── hooks/        # Custom hooks
│   │   ├── utils/        # Frontend utilities
│   │   └── App.tsx
│   ├── public/           # Static assets
│   ├── package.json
│   └── tsconfig.json
│
├── backend/              # Node.js API
│   ├── src/
│   │   ├── routes/       # API endpoints
│   │   ├── controllers/  # Request handlers
│   │   ├── models/       # Database models
│   │   ├── middleware/   # Express middleware
│   │   ├── services/     # Business logic
│   │   └── server.ts
│   ├── package.json
│   └── tsconfig.json
│
├── shared/               # Shared code
│   ├── types/           # TypeScript types
│   └── utils/           # Shared utilities
│
├── .gitignore
├── .env.example
└── README.md
```

## Migration Plan

I can help you:
1. Create the directory structure
2. Move files to appropriate locations
3. Update import paths
4. Configure build tools
5. Update .gitignore

Would you like me to proceed with the migration?
