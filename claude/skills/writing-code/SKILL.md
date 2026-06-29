---
name: writing-code
description: The user's personal code style. MUST be used whenever writing or editing code in ANY language - read this file plus the matching languages/<lang>.md before producing code. Covers functional/immutable style, naming, comments, architecture, and per-language idioms.
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.mjs"
  - "**/*.cljs"
  - "**/*.clj"
  - "**/*.cljc"
  - "**/*.rs"
  - "**/*.c"
  - "**/*.h"
  - "**/*.cpp"
  - "**/*.java"
  - "**/*.py"
  - "**/*.go"
---

# Writing code in my style

> **Always-on rule:** before writing or editing code, read this file AND the matching
> `languages/<lang>.md`. Do not skip it. Applies to new code in my own projects; when editing a
> codebase with its own established conventions, those win.

## Cross-language principles

These hold in every language:

1. **Functional & immutable, Clojure-inspired.** Prefer pure functions. Avoid mutation —
   return new values. Push side effects to the edges.
2. **Composition over inheritance — always.** Build behavior by composing functions and data,
   not class hierarchies.
3. **Iteration via higher-order functions.** Prefer `map` / `filter` / `reduce` / `forEach`
   (and sequence helpers) over imperative `for` / `while` loops for direct iteration.
4. **Absence is `undefined`/nil, never `null`.** From Clojure nil-punning. In languages with
   both, never use `null`; treat absence as `undefined`. Avoid `=== null` checks — use
   `=== undefined` or truthiness. In Java, prefer `Optional`.
5. **Business logic lives in a `lib`-style core; entry points are thin.** Routes / API handlers
   / controllers / `main` just load data, call `lib` functions, and return results. Never put
   business logic in the entry layer.
6. **Comments are sparse and explain *why*.** Short, multiline, only for non-obvious things —
   hidden constraints, workarounds, subtle invariants, or links to related code/docs. No
   banners, no section dividers, no comment block longer than the code it describes. Clean
   functional code does the talking.
7. **Prefer a portable, standard-library-style toolset over ad-hoc helpers.** Reach for the
   curated utilities (e.g. `Result`/`Ok`/`Err`, `objectUtils`, `arrayUtils`) before writing a
   one-off helper.

## Per-language files (read the relevant one)

| Language | File |
|----------|------|
| TypeScript / JavaScript | `languages/typescript.md` |
| <!-- add as we build them: rust.md, clojure.md, c.md, java.md, python.md --> | |

## References

- `references/typescript-utils.md` — index of the portable TS utility toolset.

## Related skills

- **`jam-plus`** — invoke additionally when working in a JAM+ project (depends on
  `@jambnc/common` or `@jam/schemas`): domain types, package registry setup, conventions.
