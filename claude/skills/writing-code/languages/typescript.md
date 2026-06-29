# TypeScript / JavaScript

Read this together with the cross-language principles in `../SKILL.md`. These are the
TS/JS-specific expressions of that style.

## Functions

- **Always** `const fn = () => {}` (arrow). **Never** the `function` keyword.
- **Never** the `class` keyword. Model behavior with functions + plain objects/closures, and
  state with tagged unions (`Union` / `Result` from the toolset). Composition over inheritance,
  always.

## Null vs undefined

- Never produce or compare against `null`. Absence is `undefined` (Clojure nil-punning).
- Don't write `=== null`. Use `=== undefined`, truthiness, or the `defined(x)` guard
  (`x != null`) from `functionUtils`.

## Iteration

- Prefer `map` / `filter` / `reduce` / `forEach` (and the `arrayUtils` helpers) over `for` /
  `while` loops for direct iteration.

## Architecture (ESM)

- Business logic lives in `lib/`. The package's `index.ts` (the API surface) is **thin**: it
  imports from `lib/`, wires/exposes, and does nothing else. No business logic in `index.ts`,
  route handlers, or controllers — those load data, call `lib/` functions, return responses.
- `"type": "module"` ESM. Prefer named exports.

## Use the toolset — don't roll your own

Before writing a helper, check `../references/typescript-utils.md`. Default to:
- `Result<T,E>`, `Ok()`, `Err()`, `tryCatch` (from `result`) for expected errors — prefer over
  throwing.
- `objectUtils` (`getIn`, `updateIn`, `mapValues`, `invert`, ...) for immutable object work.
- `arrayUtils` (`groupBy`, `keyBy`, `first`, `unique`, `keep`, ...) for sequences.
- `functionUtils` (`identity`, `defined`, `memoize`, ...).

In a project that depends on `@jambnc/common`, import these from `@jambnc/common` rather than
copying them.

## Comments

- `/* */` multiline only. Short. Only for non-obvious **why** (hidden constraints, workarounds,
  invariants) or links to related code/docs.
- No banner comments, no section dividers, no large JSDoc blocks. A comment should never be
  longer than the code it describes — clean functional code documents itself.

## JAM+ projects

If the project depends on `@jambnc/common` or `@jam/schemas` (check `package.json`), this is a
JAM+ project — **also invoke the `jam-plus` skill** for domain types, the package registry
setup, and conventions.

<!-- TODO: add a short real example (a thin index.ts + a lib/ function) once confirmed. -->
