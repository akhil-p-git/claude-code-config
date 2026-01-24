# C Standards

> Reference guide for C development. Loaded as needed by Claude Code.

---

## Style Guide

- **Follow K&R style** or Linux kernel style
- **Indentation:** Tabs or 4 spaces (be consistent)
- **Line width:** 80 characters max
- **Braces:** Opening brace on same line (K&R style)

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Variables | `snake_case` | `user_count`, `is_valid` |
| Functions | `snake_case` | `get_user`, `calculate_sum` |
| Macros | `UPPER_SNAKE_CASE` | `MAX_SIZE`, `DEBUG_LOG` |
| Constants | `UPPER_SNAKE_CASE` | `BUFFER_SIZE`, `PI` |
| Types (typedef) | `snake_case_t` | `user_t`, `config_t` |
| Structs | `snake_case` | `struct user`, `struct config` |
| Enums | `UPPER_SNAKE_CASE` | `enum { STATUS_OK, STATUS_ERROR }` |

## Header Files

```c
// user.h
#ifndef USER_H
#define USER_H

// Or use: #pragma once

#include <stddef.h>
#include <stdbool.h>

// Forward declarations
struct database;

// Type definitions
typedef struct user {
    int id;
    char name[64];
    char email[128];
    bool active;
} user_t;

// Function declarations
user_t *user_create(const char *name, const char *email);
void user_destroy(user_t *user);
bool user_validate(const user_t *user);
int user_save(struct database *db, const user_t *user);

#endif // USER_H
```

## Memory Management

```c
#include <stdlib.h>
#include <string.h>

// ALWAYS check malloc return values
user_t *user_create(const char *name, const char *email) {
    user_t *user = malloc(sizeof(user_t));
    if (user == NULL) {
        return NULL;  // Handle allocation failure
    }

    // Initialize all fields
    memset(user, 0, sizeof(user_t));

    // Safe string copy
    strncpy(user->name, name, sizeof(user->name) - 1);
    strncpy(user->email, email, sizeof(user->email) - 1);

    return user;
}

// ALWAYS free allocated memory
void user_destroy(user_t *user) {
    if (user != NULL) {
        // Clear sensitive data before freeing
        memset(user, 0, sizeof(user_t));
        free(user);
    }
}

// Initialize pointers to NULL
void init_context(context_t *ctx) {
    ctx->buffer = NULL;
    ctx->user = NULL;
    ctx->size = 0;
}

// Cleanup function pattern
void cleanup_context(context_t *ctx) {
    free(ctx->buffer);
    ctx->buffer = NULL;

    user_destroy(ctx->user);
    ctx->user = NULL;
}
```

## Error Handling

```c
#include <errno.h>

// Return codes: 0 for success, negative for errors
#define ERR_INVALID_ARG  (-1)
#define ERR_NO_MEMORY    (-2)
#define ERR_IO_ERROR     (-3)
#define ERR_NOT_FOUND    (-4)

// Error handling pattern
int read_config(const char *path, config_t *config) {
    if (path == NULL || config == NULL) {
        return ERR_INVALID_ARG;
    }

    FILE *file = fopen(path, "r");
    if (file == NULL) {
        // Use errno for system call errors
        if (errno == ENOENT) {
            return ERR_NOT_FOUND;
        }
        return ERR_IO_ERROR;
    }

    // Process file...
    int result = parse_config(file, config);

    fclose(file);
    return result;
}

// Usage with goto for cleanup
int complex_operation(void) {
    int result = 0;
    char *buffer = NULL;
    FILE *file = NULL;

    buffer = malloc(BUFFER_SIZE);
    if (buffer == NULL) {
        result = ERR_NO_MEMORY;
        goto cleanup;
    }

    file = fopen("data.txt", "r");
    if (file == NULL) {
        result = ERR_IO_ERROR;
        goto cleanup;
    }

    // Do work...

cleanup:
    free(buffer);
    if (file != NULL) {
        fclose(file);
    }
    return result;
}
```

## Safe String Handling

```c
#include <string.h>
#include <stdio.h>

// NEVER use strcpy, sprintf, gets - use safe versions

// Safe string copy
size_t safe_strcpy(char *dest, size_t dest_size, const char *src) {
    if (dest == NULL || dest_size == 0) {
        return 0;
    }

    size_t src_len = strlen(src);
    size_t copy_len = (src_len < dest_size - 1) ? src_len : dest_size - 1;

    memcpy(dest, src, copy_len);
    dest[copy_len] = '\0';

    return copy_len;
}

// Use snprintf instead of sprintf
void format_message(char *buffer, size_t size, const char *name, int count) {
    int written = snprintf(buffer, size, "User %s has %d items", name, count);
    if (written < 0 || (size_t)written >= size) {
        // Handle truncation or error
        buffer[size - 1] = '\0';
    }
}
```

## Macros

```c
// Use parentheses around parameters
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define ARRAY_SIZE(arr) (sizeof(arr) / sizeof((arr)[0]))

// Use do-while for multi-statement macros
#define LOG_ERROR(msg) do { \
    fprintf(stderr, "[ERROR] %s:%d: %s\n", __FILE__, __LINE__, (msg)); \
} while (0)

// Type-safe alternatives with _Generic (C11)
#define print_value(x) _Generic((x), \
    int: print_int, \
    double: print_double, \
    char *: print_string \
)(x)
```

## Struct Initialization

```c
// C99 designated initializers
user_t user = {
    .id = 1,
    .name = "John",
    .email = "john@example.com",
    .active = true
};

// Zero initialization
user_t empty_user = {0};

// Compound literals
void process(user_t user);
process((user_t){.name = "Test", .active = true});
```

## Common Patterns

```c
// Opaque pointer pattern (hide implementation)
// user.h
typedef struct user user_t;
user_t *user_create(void);
void user_destroy(user_t *user);

// user.c
struct user {
    int id;
    char name[64];
    // Implementation details hidden
};

// Callback pattern
typedef void (*event_handler_t)(void *context, int event);

void register_handler(event_handler_t handler, void *context);
```

---

## Quick Checklist

- [ ] All malloc/calloc return values checked
- [ ] All allocated memory freed
- [ ] Pointers initialized to NULL
- [ ] No buffer overflows (use safe string functions)
- [ ] Error codes returned (0 = success, negative = error)
- [ ] errno used for system call errors
- [ ] Include guards in all headers
- [ ] Macros properly parenthesized
