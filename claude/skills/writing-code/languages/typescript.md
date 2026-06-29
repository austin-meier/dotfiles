# TypeScript / JavaScript

Read this together with the cross-language principles in `../SKILL.md`. These are the
TS/JS-specific expressions of that style.

## Functions

- **Always** `const fn = () => {}` (arrow). **Never** the `function` keyword.
- **Never** the `class` keyword. Model behavior with functions + plain objects/closures, and
  state with tagged unions (`Union` / `Result` from the toolset). Composition over inheritance,
  always.

## Types vs interfaces

- **Default to `type`.** Compose with `&` (intersection) instead of `interface` inheritance
  (`extends`). Props, data shapes, DTOs, unions, and intermediate types are always `type`.
- **Reserve `interface` for genuine API-level behavior contracts:** something that is a
  composable, replaceable API boundary (callers implement or swap it). Behavior contract =
  `interface`; data contract = `type`.

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

## React

Always use **Atomic Design** to structure React components. Organize by composition level and
compose upward:

```
components/
  atoms/       # Buttons, Inputs, Labels - smallest building blocks
  molecules/   # SearchBar, FormField - a few atoms combined into a useful unit
  organisms/   # Header, NavigationBar, ProductGrid - molecules/atoms forming a distinct UI section
  templates/   # DashboardLayout, AuthLayout - arrangements of organisms into a page skeleton
  pages/       # HomePage, SettingsPage - a template wired to real data/state for a specific use
```

Place each component at the right level. Combined with the rules above: arrow-function
components (never the `function` keyword), never the `class` keyword, composition over
inheritance.

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

## Testing

See the cross-language testing rule in `../SKILL.md`. TS/JS specifics:

- For a plain Node/TS project, a simple `test.js` (or the built-in `node --test`) wired to a
  `"test": "node test.js"` script in `package.json` is usually enough. Don't pull in a heavy test
  framework just to test some pure functions.
- For a **Vite** project, use **vitest**.

## JAM+ projects

If the project depends on `@jambnc/common` or `@jam/schemas` (check `package.json`), this is a
JAM+ project — **also invoke the `jam-plus` skill** for domain types, the package registry
setup, and conventions.

<!-- TODO: add a short real example (a thin index.ts + a lib/ function) once confirmed. -->
