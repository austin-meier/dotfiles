# The JSON-Schema → types pipeline

The most important JAM convention: **domain models are JSON Schema, owned by the `schema` repo,
and TS/Zod types are generated from them.** Don't hand-define domain shapes downstream.

## Flow

```
schema repo (~/coding/schema/jam)              author/commit JSON Schema here
  resources/schemas/v1/**.json
        │  commit triggers GitHub Action
        ▼
generate-typescript-from-json-schema-action    JSON Schema -> Zod + TS
        │  updates the output repo
        ▼
ts-types-jam  (JAMBNC/ts-types-jam)             ESM module of Zod schemas + TS types
        │  consumed as a github: dependency
        ▼
@jam/schemas  in consumer projects             olympus, ReactEcom, shop-designer-app, ...
```

## The schema repo is half-generated, half-manual

It's a **Java/Maven** project. Two sources of JSON Schema, both ending up under
`resources/schemas/v1/`:

- **Generated from Java** — POJOs/annotations under `src/main/java/com/jam/schema/v1/**` produce
  schemas via a build step. (The user considers the Java-generation route a poor choice but it's
  in place for part of the model.)
- **Manual** — hand-written JSON Schema under `resources/schemas/v1/manual/**`.

When adding or changing a model, determine which half it belongs to: edit the Java source for
generated schemas, or the JSON directly for `manual/` schemas. Then commit so the action
regenerates `@jam/schemas`.

## Working rules

- New/changed domain shape → do it in `schema`, never redefine it in a consumer repo.
- Consume types from `@jam/schemas`; pair Zod schemas with `zodUtils.extractDefaults` where useful.
- Versioned under `v1/` — keep new models consistent with that versioning.

See `schema-index.md` for the catalog of objects and their locations.
