---
name: jam-plus
description: High-level map of JAM+ (jambnc / jamplus) - the user's employer, a DTC print e-commerce company - its systems, repos, domain model, and the JSON-Schema-driven type pipeline. Use whenever working in any JAM codebase (references jam/jambnc/jamplus, or depends on @jambnc/common, @jambnc/font, @jamplus/kronos, or @jam/schemas). Composes with the writing-code skill.
---

# JAM+

JAM+ (`jambnc`, `jamplus`) is the user's employer: a **direct-to-consumer print company** running
**envelopes.com**, **jampaper.com**, and **folders.com**. Customers design a product in a custom
designer, JAM prints it and ships it.

**This skill composes with `writing-code`** — all personal style rules still apply; this adds JAM
domain knowledge. Most JAM work is TypeScript/React + Node.

## The two things that matter most

1. **Domain models are JSON Schema, owned by the `schema` repo.** Any domain model or
   cross-language shape is authored as JSON Schema there and committed; a GitHub Action then
   generates Zod + TS types and publishes them as `@jam/schemas`. **Never hand-define a domain
   shape in a consumer project — add/change it in `schema` and consume `@jam/schemas`.** See
   `references/schema-pipeline.md` and `references/schema-index.md`.
2. **Shared logic lives in `@jambnc/common`** (the `jam-common` package in the `olympus`
   monorepo): business logic, schema manipulation, and the portable utility toolset (the same
   utils indexed in `writing-code`). Import from there rather than re-implementing. See
   `references/packages.md`.

## Idiomatic reference & precedence

The **olympus** monorepo is the **most idiomatic example** of consuming `@jambnc/common` and
`@jam/schemas` — follow its overall setup and usage patterns when writing JAM code. (olympus
pulls `jam-common` locally via the npm workspace, so it skips the GitHub/`.npmrc` pull other repos
need; that pattern is in `references/packages.md`.)

**Personal `writing-code` style is still the dominant writer** — when an olympus convention and the
personal style guide conflict, the personal style guide wins.

## Systems map

| System | What it is | Where |
|--------|-----------|-------|
| **olympus** | Monorepo for the modern designer (most active). Workspaces: `alchemy` (canvas render engine), `hermes` (the React product designer), `@jambnc/common`, `@jambnc/font`, `@jamplus/kronos` (iframe + postMessage embed bridge). Embeddable in multiple storefronts. | `~/coding/js/olympus` |
| **schema** | Source of truth for domain models (JSON Schema). Java/Maven project; schemas under `resources/schemas/v1/`. | `~/coding/schema/jam` |
| **@jam/schemas (ts-types-jam)** | Generated Zod+TS module published from `schema` via the action. Consumed everywhere. | repo `JAMBNC/ts-types-jam` |
| **generate-typescript-from-json-schema-action** | Custom GitHub Action (user-authored) that turns the JSON Schemas into the `ts-types-jam` module. | `~/coding/js/generate-typescript-from-json-schema-action` |
| **shop-designer-app** | Embeds the hosted olympus/hermes designer into Shopify. Hosted on **AWS ECS**. | `~/coding/js/shop-designer-app` |
| **magento2 (`jam`)** | Historical/primary storefront (PHP/Magento2). Contains two legacy designers (old folders.com JS designer; the `Kadro\Designer` intermediary module). | `~/coding/php/jam` |
| **ReactEcom** | Hand-rolled React front end for Magento (predates olympus, older structure; now pulls in `@jambnc/common`). | `~/coding/js/reactecom` |
| **netsuite-kit** | NetSuite dashboard + bundled SDF project (NetSuite scripts: feed management to Shopify/Magento, deploy/validate). | `~/coding/js/netsuite-kit` |

Full paths, git remotes, and status: `references/systems.md`.

## Data flow (high level)

**NetSuite is the ERP and (currently) de-facto PIM.** Product/inventory/pricing data feeds out
of NetSuite → Magento and → Shopify; orders flow back into NetSuite. The designer (hermes, via
alchemy) builds to a **JS bundle on S3**; storefronts load it and talk to it through
`@jamplus/kronos` (iframe + postMessage). On Shopify it's embedded via `shop-designer-app` (AWS
ECS). The designer produces a `DesignState` that travels with the order.

## Where things are headed

- **Platform migration Magento2 → Shopify** (management mandate, in progress). Much current work
  is making NetSuite ↔ Shopify order/feed propagation correct.
- **olympus** is the strategic bet: a portable TS+React designer, eventually paired with a new
  storefront-agnostic designer backend (no repo yet, not the user's responsibility), to be sold
  to other companies for a % fee.

## References

- `references/systems.md` — every repo: path, remote, purpose, status.
- `references/packages.md` — olympus workspaces, `@jambnc/common`, registry/`.npmrc` setup.
- `references/schema-pipeline.md` — the JSON-Schema → Zod/TS → `@jam/schemas` pipeline.
- `references/schema-index.md` — index of domain schema objects and where to find them.
- `../writing-code/references/typescript-utils.md` — the utility toolset (bundled in `@jambnc/common`).
