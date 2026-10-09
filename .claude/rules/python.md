---
description: "Python standards (3.12+, uv, ruff, typed)"
paths:
  - "**/*.py"
  - "**/pyproject.toml"
  - "**/requirements*.txt"
---

# Python

## Tooling — follow what the project already uses; these are the defaults for new projects
- Environments and dependencies: `uv` (`uv add`, `uv sync`, `uv run …`); commit `uv.lock`. Never `pip install` into the system interpreter — Arch's Python is externally managed (PEP 668) and it breaks pacman packages.
- Lint and format with ruff (`uv run ruff check --fix .` and `uv run ruff format .`); it replaces black, isort, and flake8. Type-check with whatever the project configures (`pyright` or `mypy --strict`).
- Run tools inside the project environment (`uv run pytest -q`), never a globally installed copy.

## Code
- Annotate public functions; use modern syntax: `list[str]`, `X | None`, `type` aliases (3.12+). No `typing.List`/`Optional` in new code.
- Validate external data (requests, files, env, LLM output) at the boundary with Pydantic v2 (`model_validate`, `model_dump`, `field_validator`) — not the v1 API (`parse_obj`, `.dict()`, `@validator`). Use `@dataclass(slots=True)` (frozen where possible) for internal records.
- `pathlib.Path` over `os.path`; `logging.getLogger(__name__)` over `print` outside scripts.
- No mutable default arguments, no bare `except:`; catch specific exceptions and chain with `raise … from err`.
- Async: `asyncio.TaskGroup` (3.11+) for concurrent tasks; never block the event loop (use `httpx.AsyncClient`, `asyncio.to_thread` for blocking calls).
- Money and exact quantities: `decimal.Decimal`, never `float`.

## Tests
- pytest with plain `assert`; fixtures over setup methods; `tmp_path` for files; `@pytest.mark.parametrize` for case tables; freeze time and seed randomness.
- Iterate with `uv run pytest -q -x <path>`; run the full suite before calling the work done.
