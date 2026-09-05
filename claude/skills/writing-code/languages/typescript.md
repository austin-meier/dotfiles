# TypeScript / JavaScript

TS/JS specifics on top of the principles in `../SKILL.md`.

## Functions and classes

- Always `const fn = () => {}`. Never the `function` keyword.
- Never `class`. Behavior is functions plus plain objects and closures. State is tagged unions
  (`Union` / `Result` from the toolset).

## Types vs interfaces

- Default to `type`. Compose with `&`, not `interface extends`. Props, data shapes, DTOs, unions,
  and intermediates are all `type`.
- `interface` only for a genuine behavior contract that callers implement or swap. Behavior
  contract = `interface`; data contract = `type`.

## Absence

`undefined`, never `null`. Test with `=== undefined`, truthiness, or `defined(x)` from
`functionUtils` (the `x != null` guard).

## Architecture

- `"type": "module"` ESM, named exports.
- Business logic in `lib/`. `index.ts`, route handlers, and controllers import from `lib/`, wire
  it up, and do nothing else.

## React

Atomic Design, composed upward:

```
components/
  atoms/       Buttons, Inputs, Labels
  molecules/   SearchBar, FormField
  organisms/   Header, NavigationBar, ProductGrid
  templates/   DashboardLayout, AuthLayout
  pages/       HomePage, SettingsPage, a template wired to real data
```

Arrow-function components, no classes, composition over inheritance.

## The toolset

Before writing a helper, read the real source at `../../../libs/typescript/utils/` (resolves to
`~/.config/claude/libs/typescript/utils/`). The `.ts` files are the index; trust them over this
map. In a project that depends on `@jambnc/common`, import from it instead of copying.

**Core**
- `result`: `Result<T,E>` typed error handling; prefer over throwing. `Ok`, `Err`, `isOk`/`isErr`,
  `map`, `orElse`, `orElseCall`, `orElseMaybe`, `tryCatch`, `tryCatchAsync`, `collectOk`.
- `objectUtils`: immutable nested access/transform. `getIn`, `updateIn`, `deleteIn`, `resolveIn`,
  `mapValues`, `mapKeys`, `deepMerge`, `invert`, `isObject`.
- `arrayUtils`: sequences. `first`/`last`, `butFirst`/`butLast`, `count`, `groupBy`, `keyBy`,
  `indexBy`, `unique`/`uniqueBy`, `keep`, `intersect`/`intersectBy`, `range`/`rangeInclusive`, `Sorting`.
- `functionUtils`: `identity`, `defined`, `isEmpty`, `memoize`, `take`.
- `stringUtils`: `isString`, `capitalizeFirst`, `asHex`, `decodeHtmlEntities`, `acronymize`,
  `levenshtein`, `fuzzyScore`.
- `numberUtils`: `parseNumber` (returns `Result`, not `NaN`/throw), `fromOrdinal`, `toOrdinal`.
- `union`: `Union<Mappings>` tagged-union builder; backs `Result`. Use instead of class hierarchies.

**Domain / platform**
- `dimension`: `Dim` helpers, branded `Dimension` (`'in'|'pt'|'cm'|'m'|'mm'`), `Dimensionable`.
- `pricingUtils`: tiered/bundle pricing (`getTier`, `getUnitPriceAtTier`, `getAddToCartPrice`, ...).
- `coverageUtils`: `calculateCoverage`, `getCoverageAdder`.
- `zodUtils`: `extractDefaults(schema)` plus zod helpers (pairs with `@jam/schemas`).
- `fetchUtils`: `fetchFrom<T>(...)` typed fetch wrapper.
- `environmentUtils`: `getEnvironmentValue`, `getOrThrow`, `getEnvironment`.
- `jwtUtils`: `decodeJwtPayload`, `isJwtExpired`.
- `cookieUtils`: `parseCookie`, `getDocumentCookie` (memoized).

## Comments

Zero, per `../SKILL.md`. No JSDoc anywhere: the type signature is the documentation. Directives
stay on one line and are fine (`// eslint-disable-next-line`, `// @ts-expect-error`,
`/// <reference />`). Where you wanted a comment above an `if`, write a named intermediate
`const` instead (`const hasExpiredSession = ...`).

## Testing and verification

- Plain Node/TS project: `node --test`, or a simple `test.js`, wired to `"test"` in `package.json`.
- Vite project: vitest.
- Before you're done: TypeScript LSP diagnostics on every touched file, or `tsc --noEmit`.
