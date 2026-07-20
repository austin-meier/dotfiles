# JAM+ systems & repos

Canonical paths follow the `~/coding/{language}/{project}` convention and the user keeps them at
the same path (or symlinked) across machines. If a path is missing on a given machine, the repo
can be cloned from the remote.

| Repo | Path | Remote | Role / notes |
|------|------|--------|--------------|
| **olympus** | `~/coding/js/olympus` | `git@github.com:JAMBNC/olympus.git` | Monorepo (npm workspaces) for the modern designer. **Most active.** Packages below. |
| **schema** | `~/coding/schema/jam` | `git@github.com:JAMBNC/schema.git` | JSON-Schema source of truth for all domain models. Java/Maven project. |
| **ts-types-jam** | (consumed as `@jam/schemas`) | `git@github.com:JAMBNC/ts-types-jam.git` | **Generated** output of the action — Zod+TS domain types as an ESM module. Don't hand-edit; it's regenerated. |
| **generate-typescript-from-json-schema-action** | `~/coding/js/generate-typescript-from-json-schema-action` | `git@github.com:JAMBNC/generate-typescript-from-json-schema-action.git` | User-authored GitHub Action: JSON Schema → Zod+TS → updates `ts-types-jam`. |
| **shop-designer-app** | `~/coding/js/shop-designer-app` | `git@github.com:JAMBNC/shop-designer-app.git` | Embeds the hosted olympus/hermes designer into Shopify. Hosted on **AWS ECS** (predates the serverless template below). |
| **shopify-app-template** | `~/coding/js/shopify-jamplus-app-template` | `git@github.com:JAMBNC/shopify-jamplus-app-template.git` | **Project-agnostic starter for new JAM+ Shopify apps.** React Router 7, serverless on AWS Lambda via **SST**, DynamoDB sessions. Clone → rename → build. See `shopify-apps.md`. |
| **shopify-fulfillment-app** | `~/coding/js/shopify-jamplus-fulfillment-app` | `git@github.com:JAMBNC/shopify-jamplus-fulfillment-app.git` | First app built on the template (and the reference SST build). Registers JAM+ as a Shopify **fulfillment service**; proxies Shopify ↔ JAM+ backend (OMS) over SQS FIFO. See `shopify-apps.md`. |
| **magento2** | `~/coding/php/jam` | `github.com/JAMBNC/magento2.git` | Historical/primary storefront (PHP/Magento2). Holds two legacy designers (see below). |
| **ReactEcom** | `~/coding/js/reactecom` (intended name `react-ecom`) | `git@github.com:JAMBNC/ReactEcom.git` | Hand-rolled React front end for Magento (package name "Navi UI Components"). First React project (pre-olympus), older structure; consumes `@jambnc/common` + `@jam/schemas`. Example of the **GitHub-pull** consumption path (`.npmrc` + `github:` dep). For idiomatic usage overall, prefer **olympus**. |
| **netsuite-kit** | `~/coding/js/netsuite-kit` | `git@github.com:JAMBNC/netsuite-kit.git` | NetSuite dashboard + bundled **SDF** project (NetSuite scripts: feed mgmt to Shopify/Magento, deploy + validate code). |
| **kronos-integration-example** | `~/coding/js/kronos-integration-example` | `git@github.com:JAMBNC/kronos-integration-example-vanilla.git` | Example (vanilla JS) of using `@jamplus/kronos` to embed/communicate with the designer. Reference only. |

## olympus workspaces (`~/coding/js/olympus/packages/*`)

| Package dir | Published name | Purpose |
|-------------|----------------|---------|
| `alchemy` | `alchemy` | Canvas/document web renderer and visual editor (rendering engine). |
| `hermes` | `hermes` | The React product designer (the only current one). Built on alchemy. |
| `jam-common` | `@jambnc/common` | Common definitions: business logic, schema manipulation, portable utils. |
| `font` | `@jambnc/font` | Font loading + measurement utilities. |
| `kronos` | `@jamplus/kronos` | Manages the **iframe + postMessage** communication to the loaded designer (hermes) — the embed/host bridge. |

## Designer lineage (oldest → newest)

1. **Old folders.com designer** — JavaScript-only, lives on inside the Magento repo. Legacy.
2. **`Kadro\Designer` module** — an "intermediary" designer, also in the Magento repo.
3. **olympus / hermes** — the modern, portable TS+React designer. Current and strategic;
   embedded into Shopify via `shop-designer-app`.

## Hosting

- **The designer bundle** (hermes + kronos) currently builds to a **JS bundle on S3**. Storefronts
  load that bundle and talk to it via `@jamplus/kronos` (iframe + postMessage).
- **shop-designer-app** runs on **AWS ECS** — the Shopify-side app that embeds/serves the designer
  into Shopify. It predates the serverless standard.
- **New Shopify apps** deploy **serverless** (AWS Lambda + CloudFront via SST, DynamoDB sessions),
  built from the `shopify-app-template`. This is the going-forward pattern, not ECS. See
  `shopify-apps.md`.

## Platform state

Migrating **Magento2 → Shopify** (management mandate, in progress). NetSuite remains the ERP /
de-facto PIM on both sides of the migration.

## Ignored / not core

Present under `~/coding` but not part of the active JAM system map — do not treat as canonical:
`designer`, `competitve-price-tool` (ignored), and `JAMtone` (a one-off project to convert color
definitions).
