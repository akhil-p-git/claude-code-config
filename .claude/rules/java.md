---
description: "Java 21 + Spring Boot standards"
paths:
  - "**/*.java"
  - "**/pom.xml"
  - "**/build.gradle"
  - "**/build.gradle.kts"
  - "**/settings.gradle*"
  - "**/application*.yml"
  - "**/application*.properties"
---

# Java & Spring Boot

## Language (target the project's JDK; this machine defaults to 21 LTS)
- Use records for immutable data carriers/DTOs, sealed interfaces + pattern-matching `switch` for closed hierarchies, text blocks for multi-line strings, `var` only when the type is obvious from the right-hand side.
- `Optional` is for return values only — not fields or parameters. Use `orElseThrow()`/`orElse`, never a bare `get()`.
- Prefer immutable collections (`List.of`, `Map.of`, `stream.toList()`); return empty collections, never `null`.
- Money: `BigDecimal` with an explicit `RoundingMode`; compare with `compareTo`, not `equals` (scale-sensitive).
- Use try-with-resources for anything `AutoCloseable`. Never catch `Exception`/`Throwable` broadly or swallow exceptions; wrap with context and rethrow.
- Keep lambdas in `map`/`filter` side-effect free; use a plain loop when it reads clearer.
- Log with SLF4J parameterized messages (`log.info("user {} created", id)`), never string concatenation or `System.out`.

## Spring Boot
- Constructor injection with `final` fields (single constructor, no `@Autowired`); never field injection.
- Bind config with `@ConfigurationProperties` on records (+ `@Validated`) instead of scattered `@Value`.
- Controllers stay thin: validate (`@Valid` + Jakarta Bean Validation), delegate to a service, map to DTO records. Never expose JPA entities in API responses.
- Errors: a `@RestControllerAdvice` returning `ProblemDetail` (RFC 9457); no stack traces in responses.
- `@Transactional` belongs on public service methods; self-invocation bypasses the proxy, so calls within the same class are not transactional.
- JPA: set `spring.jpa.open-in-view=false`; kill N+1 with fetch joins / `@EntityGraph` / DTO projections; check generated SQL on hot paths.
- Schema via Flyway or Liquibase migrations; `ddl-auto` is `validate` (or `none`) outside throwaway prototypes, never `update`.
- Virtual threads (`spring.threads.virtual.enabled=true`) suit blocking-I/O services on JDK 21+; avoid long `synchronized` blocks around blocking calls (they pin carrier threads before JDK 24).
- Expose Actuator `health` with liveness/readiness groups for container probes; never expose all actuator endpoints publicly.

## Build & Test
- Always use the wrapper (`./mvnw`, `./gradlew`), never a system Maven/Gradle. Verify with `./mvnw -q verify` or `./gradlew build`.
- JUnit 5 + AssertJ + Mockito. Prefer slice tests (`@WebMvcTest`, `@DataJpaTest`) and Testcontainers (real Postgres) over H2 for anything touching SQL.
- Name tests by behavior (`rejectsTransferWhenBalanceInsufficient`), one behavior per test.
