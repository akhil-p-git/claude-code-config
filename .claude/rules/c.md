---
description: "C language standards"
paths:
  - "**/*.c"
  - "**/*.h"
---

# C

- Follow the project's existing style (K&R, 4 spaces, 80 columns when there is none). `snake_case` functions and variables, `UPPER_SNAKE_CASE` macros, `snake_case_t` typedefs.
- Check every allocation and every I/O/syscall return value. Free what you allocate; use a single `goto cleanup` exit for functions that acquire several resources. Initialize pointers to `NULL` and set them to `NULL` after `free`.
- Strings: `snprintf` instead of `sprintf`; never `strcpy`/`strcat`/`gets`. Don't use `strncpy` as a "safe" copy — it doesn't NUL-terminate on truncation; use `snprintf(dst, sizeof dst, "%s", src)` or `strlcpy` (glibc ≥ 2.38) and check for truncation.
- Use `size_t` for sizes and indices; check multiplications and additions that feed allocation sizes for overflow. No variable-length arrays.
- Headers get include guards or `#pragma once`. Parenthesize macro parameters; wrap multi-statement macros in `do { … } while (0)`; prefer `static inline` functions to function-like macros.
- Build during development with `-Wall -Wextra -Werror -g -fsanitize=address,undefined`; run the tests under the sanitizers (and `valgrind` when available) before calling a change done.
