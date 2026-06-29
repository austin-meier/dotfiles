# TypeScript utility toolset (index)

A portable, Clojure-inspired standard-library-style toolset. **Reach for these before writing
any custom helper.** The same modules ship inside `@jambnc/common` (import from there in JAM
projects — see the `jam-plus` skill); the authoritative source copy lives in this repo at
`claude/libs/typescript/utils/` if you need to read an implementation.

Conventions throughout: pure functions, immutable (return new values, never mutate inputs),
absence is `undefined` not `null`.

## result — `Result<T, E>` for typed error handling

Prefer `Result` over throwing for expected/recoverable errors.

| Export | Signature | Notes |
|--------|-----------|-------|
| `Ok` | `<T>(value: T) => Result<T, never>` | success case |
| `Err` | `<E>(error: E) => Result<never, E>` | error case |
| `isOk` / `isErr` | `(r) => boolean` (type guards) | narrowing |
| `map` | `(r, fn) => Result` | map the Ok value |
| `orElse` | `(r, defaultValue) => T` | unwrap or default |
| `orElseCall` | `(r, () => T) => T` | unwrap or lazy default |
| `orElseMaybe` | `(r, ...) => T \| undefined` | unwrap or undefined |
| `tryCatch` | `<T,E>(fn: () => T) => Result<T,E>` | wrap a throwing call |
| `tryCatchAsync` | `<T,E>(fn: () => Promise<T>) => Promise<Result<T,E>>` | async wrap |
| `collectOk` | `(results: Result<T,E>[]) => T[]` | keep only Ok values |

`Result` also carries methods (`ResultMethods<T,E>`) — `.isOk()`, `.isErr()`, etc. Built on the
`Union` helper below.

## objectUtils — immutable nested access/transform

| Export | Signature | Notes |
|--------|-----------|-------|
| `getIn` | `(obj, [k1, k2, ...]) => value \| undefined` | typed deep get (overloaded to depth) |
| `updateIn` | `(obj, keys, fn) => obj` | immutable deep update |
| `deleteIn` | `(obj, keys) => obj` | immutable deep delete |
| `resolveIn` | `<T>(obj, ...) => T` | resolve a nested path |
| `mapValues` | `(obj, (v) => u) => obj` | map over values |
| `mapKeys` | `(obj, (k) => j) => obj` | map over keys |
| `deepMerge` | `(a, b) => merged` | recursive merge |
| `invert` | `(obj) => obj` | swap keys/values |
| `isObject` | `(t) => t is object` | guard |

## arrayUtils — sequence operations

| Export | Signature | Notes |
|--------|-----------|-------|
| `first` / `last` | `<T>(arr) => T \| undefined` | safe ends |
| `butFirst` / `butLast` | `<T>(arr) => T[]` | drop one end |
| `count` | `(arr \| undefined) => number` | nil-safe length |
| `groupBy` | `(arr, (t) => K) => Record<K, T[]>` | group into buckets |
| `keyBy` | `(arr, key) => Record<K, T>` | index by own key |
| `indexBy` | `(arr, (t) => K) => Record<K, T>` | index by fn |
| `unique` / `uniqueBy` | `(arr[, f]) => T[]` | dedupe |
| `keep` | `(xs, (t) => R \| nil) => R[]` | map + drop nil (Clojure `keep`) |
| `intersect` / `intersectBy` | `(sets[, fn]) => T[]` | set intersection |
| `range` / `rangeInclusive` | `(start, end?) => number[]` | numeric ranges |
| `Sorting` | object | comparator helpers |

## functionUtils — functional primitives

| Export | Signature | Notes |
|--------|-----------|-------|
| `identity` | `<T>(x) => x` | |
| `defined` | `<T>(x) => x is T` | `x != null` guard — use to filter out nil |
| `isEmpty` | `<T>(x) => boolean` | emptiness check |
| `memoize` | `(fn) => fn` | cache by args |
| `take` | `(iterable, n) => T[]` | first n of any iterable |

## stringUtils

`isString`, `capitalizeFirst`, `asHex`, `decodeHtmlEntities`, `acronymize`,
`levenshtein(a,b)`, `fuzzyScore(query, text)`.

## numberUtils

`parseNumber(s?) => Result<number, NumberParseError>`, `fromOrdinal`, `toOrdinal` — parsing
returns `Result`, not `NaN`/throw.

## union — `Union<Mappings>`

Tagged-union (sum type) builder used by `Result`. Use for discriminated unions instead of
class hierarchies.

## Domain / platform modules (use when relevant)

- **dimension** — `Dim` helpers + branded `Dimension` type (`'in' | 'pt' | 'cm' | 'm' | 'mm'`),
  `Dimensionable`.
- **pricingUtils** — tiered/bundle pricing (`getTier`, `getUnitPriceAtTier`, `getAddToCartPrice`,
  `getBestQuantityOption`, ...). JAM commerce pricing.
- **coverageUtils** — ingredient/coverage maps (`calculateCoverage`, `getCoverageAdder`).
- **zodUtils** — `extractDefaults(schema)` and zod helpers (pairs with `@jam/schemas`).
- **fetchUtils** — `fetchFrom<T>(...)` typed fetch wrapper.
- **environmentUtils** — `getEnvironmentValue` (overloaded), `getOrThrow`, `getEnvironment`.
- **jwtUtils** — `decodeJwtPayload`, `isJwtExpired`.
- **cookieUtils** — `parseCookie`, `getDocumentCookie` (memoized).

<!-- Regenerate this index from claude/libs/typescript/utils when the toolset changes. -->
