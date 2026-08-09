# MCP servers

## Why there is no `mcpServers` block in `settings.json`

There used to be one, listing 20 servers. It never did anything.

`mcpServers` is **not a valid `settings.json` key**. Claude Code reads MCP server
definitions from `~/.claude.json` (user scope), a project `.mcp.json`, or the
`claude mcp add` command. `settings.json` only *governs* MCP servers — which are
allowed, enabled, or auto-approved (`enabledMcpjsonServers`, `allowedMcpServers`,
`enableAllProjectMcpServers`, …). Definitions placed there are silently ignored.

Verified on 2026-08-09 with Claude Code 2.1.226: `claude mcp list` returned only
the Vercel plugin server, none of the 20.

The block was also stale. Checked against the npm registry the same day:

| Server in the old block | Status |
| --- | --- |
| `server-fetch`, `server-time`, `server-docker`, `server-git`, `server-sqlite` | **Do not exist on npm** — never installable |
| `server-github`, `server-postgres`, `server-gdrive`, `server-aws-kb-retrieval` | **Deprecated** — "Package no longer supported" |
| `server-memory`, `server-filesystem`, `@upstash/context7-mcp` | Fine |

Anthropic moved its unmaintained reference servers to
[`modelcontextprotocol/servers-archived`](https://github.com/modelcontextprotocol/servers-archived):
AWS KB Retrieval, Brave Search, EverArt, Git, GitHub, GitLab, Google Drive,
Google Maps, PostgreSQL, Puppeteer, Redis, Sentry, Slack, SQLite. They carry no
security guarantees — the archived Postgres server shipped a
[SQL-injection bug that bypassed its read-only mode](https://securitylabs.datadoghq.com/articles/mcp-vulnerability-case-study-SQL-injection-in-the-postgresql-mcp-server/).

## How to actually add one

```bash
claude mcp add <name> -- npx -y <package>              # stdio
claude mcp add --transport http <name> <url>           # remote
claude mcp list                                        # health check
claude mcp remove <name>
```

Add `-s user` for all projects, or run inside a project for project scope.

## What to use instead

**Prefer a CLI over an MCP server where one exists.** Anthropic's guidance is that
CLI tools are the most context-efficient way to reach external services: an MCP
server's tool definitions occupy context in *every* session, while a CLI costs
nothing until called.

| Want | Use |
| --- | --- |
| GitHub | `gh` CLI — already authenticated here via keyring. Don't re-add a GitHub MCP server |
| Web fetch / search | Native `WebFetch` / `WebSearch` tools |
| Local files | Native `Read`/`Write`/`Edit`/`Glob`/`Grep` — a filesystem MCP server duplicates these |
| Time, docker, git | Shell commands via `Bash` |
| Postgres | A maintained third-party server, or `psql` via Bash. Never the archived one |
| Browser automation | `@playwright/mcp` (Microsoft, maintained) |
| Library docs | `@upstash/context7-mcp` |
| Persistent memory | `@modelcontextprotocol/server-memory`, or Claude Code's native auto-memory |

Keep the set small. Every enabled server's tool definitions are loaded into the
context window of every session, and context is the binding constraint.

## Keys

MCP `env` blocks *do* expand `${VAR}` from the startup environment — unlike the
`settings.json` top-level `env` block, which does not expand anything. Put real
values in `~/.secrets.env` (see `.env.example`).
