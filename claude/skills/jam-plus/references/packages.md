# JAM+ packages & registry

## The shared packages

These are published from the `olympus` monorepo and consumed across JAM projects:

- **`@jambnc/common`** (olympus `packages/jam-common`) — "JAM Plus Common definitions module."
  The big one: business logic, manipulation of the domain schemas, and the portable utility
  toolset (`Result`/`Ok`/`Err`, `objectUtils`, `arrayUtils`, `pricingUtils`, etc. — indexed in
  `../../writing-code/references/typescript-utils.md`). **Import shared logic/utils from here**
  instead of re-implementing.
- **`@jambnc/font`** (olympus `packages/font`) — font loading + measurement utilities.
- **`@jamplus/kronos`** (olympus `packages/kronos`) — manages the iframe + postMessage
  communication to the loaded designer (hermes); the host/embed bridge. See the
  `kronos-integration-example` repo for usage.
- **`@jam/schemas`** — generated Zod + TS domain types (see `schema-pipeline.md`). Resolves to
  `github:JAMBNC/ts-types-jam`.

## Package registry (`.npmrc`)

`@jambnc` (and JAM) packages come from **GitHub Packages**, so JAM TS projects need an `.npmrc`:

```
@jambnc:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=${GITHUB_TOKEN}
```

Never hard-code or commit the auth token — read it from an env var or a local-only `.npmrc`.
`@jam/schemas` is a `github:` git dependency in `package.json`, not a registry package.

## Idiomatic usage

**`olympus` is the reference for how to use `@jambnc/common` and `@jam/schemas` idiomatically** —
match its setup and usage patterns (subordinate to the personal `writing-code` style, which
wins on any conflict). Note olympus consumes `jam-common` *locally* via the npm workspace, so it
does not use the GitHub-pull `.npmrc` shown above.

`~/coding/js/reactecom` is the example of the **GitHub-pull** path specifically (the `.npmrc` +
`github:` dependency) — but that pattern is already captured above, so you rarely need to open it.
