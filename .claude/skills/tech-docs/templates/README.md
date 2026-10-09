<!-- README: a landing page. Say what this is, get the reader running, route them to deeper docs.
     Order follows standard-readme and makeareadme. Delete sections that would be empty; never write "N/A". -->
# project-name

<!-- One sentence under 120 characters; reuse it as the GitHub and package.json description. -->
One-sentence description of what it does and for whom.

<!-- Optional: one screenshot or GIF of the real thing for anything with a UI. Alt text describes what it shows. -->

<!-- Optional, 2-4 sentences: the problem it solves and what makes it different. No adjectives without evidence. -->

## Install

<!-- Exact prerequisites with versions taken from the manifest (engines, .nvmrc, python_requires). -->
Requires Node.js 22+ and pnpm 10.

```bash
git clone https://github.com/OWNER/REPO.git
cd REPO
pnpm install
cp .env.example .env.local   # then set the variables below
```

## Usage

<!-- The smallest real example, with its real output. Link to longer guides instead of growing this section. -->
```bash
pnpm dev
```

Open http://localhost:3000 and sign in with the seed user in `scripts/seed.ts`.

### Configuration

<!-- One row per variable, copied from .env.example and the config schema. -->
| Variable | Required | Default | Description |
|---|---|---|---|
| `DATABASE_URL` | yes | none | Postgres connection string |

## Development

<!-- The commands a contributor runs daily, verified. -->
```bash
pnpm test        # unit tests (Vitest)
pnpm lint        # ESLint + Prettier check
pnpm typecheck   # tsc --noEmit
```

## Documentation

<!-- Route to the Diátaxis pages that exist. -->
- Tutorial: [Build your first widget](docs/tutorials/first-widget.md)
- How-to guides: [docs/how-to/](docs/how-to/)
- Reference: [CLI](docs/reference/cli.md), [API](docs/reference/api.md)
- Explanation: [About the architecture](docs/explanation/architecture.md)
- Decisions: [docs/adr/](docs/adr/)

## Contributing

<!-- Whether contributions are welcome and the bar for merging. Link CONTRIBUTING.md if it exists. -->

## License

<!-- SPDX identifier and owner; keep this the last section. -->
MIT © Owner Name
