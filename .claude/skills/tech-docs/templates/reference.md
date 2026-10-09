<!-- Reference: describe and only describe. Neutral, complete, structured like the code it documents.
     Every row comes from the source (types, schema, --help output). Examples are allowed; advice is not. -->
# <Component / command / endpoint> reference

<One sentence: what this is.> Source: [`path/to/source.ts`](../../path/to/source.ts).

## Synopsis

```bash
tally export [--format csv|json] [--since <date>] <account-id>
```

## Options

| Option | Type | Default | Description |
|---|---|---|---|
| `--format` | `csv` \| `json` | `csv` | Output format |
| `--since` | ISO date | none | Only include entries on or after this date |

## Exit codes / errors

| Code | Meaning |
|---|---|
| `0` | Success |
| `2` | Invalid arguments |

## Limits

- <rate limits, sizes, timeouts, with exact numbers>

## Examples

```bash
tally export --format json --since 2026-01-01 acct_123
```
