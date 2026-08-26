# admin-ui (the JAM Admin App / OMS backend)

`admin-ui` is JAM+'s back-office app and the **OMS (order management system) backend**. It's a
"new to me" (Austin's) area of the codebase, and it's where most of the current Shopify ↔ NetSuite
order work actually lands.

| | |
|---|---|
| **Repo** | `git@github.com:JAMBNC/admin-ui.git` |
| **Local path** | `~/coding/js/jam-app` (Austin's machine) |
| **Entry point for AI** | **`CONTEXT.md` in the repo root** — read it first. It's the curated index of everything below and where to find more. |
| **Stack** | Node.js + Fastify on AWS Lambda (backend), React + Vite + Tailwind + Zustand (frontend), PostgreSQL (`jamapp`), AWS Cognito auth, S3, SQS |
| **Schemas** | Consumes the canonical JSON Schema contracts (the `schema` repo) and mirrors cross-system shapes in Zod at its boundaries. Same `@jam/schemas` pipeline as the rest of JAM. |

## What it does

Three big jobs live in one repo (one monorepo, multiple Lambda deploy targets):

1. **Order management system (OMS).** The real reason it's busy right now. It ingests Shopify orders
   (post-purchase webhooks + the fulfillment-service handoff), converts them to canonical JAM shape,
   and pushes them into **NetSuite** (the ERP). Covers order create, edits, refunds, returns,
   disputes, cancellations, payments/terms, and inventory push back to Shopify.
2. **Design management + prepress.** Managing design configurations, the prepress verification
   workflow (analyze / recolor / regenerate / approve / reject), vendor PDF generation, and design
   verification tooling.
3. **Catalog + configuration admin.** Products, styles, stocks, colors, features, processes, adders,
   partners, channels, vendors, users, ERP mappings, feeds, and the cascading "designer config" model.

## How it connects to the rest of JAM

- **Shopify → admin-ui (OMS):** post-purchase webhooks are delivered **directly** to admin-ui's
  `POST /api/v1/webhooks/shopify` (HMAC-validated), not through the fulfillment app. There's also a
  dedicated non-VPC webhook-receiver Lambda option.
- **`shopify-fulfillment-app` → admin-ui (OMS):** the fulfillment app registers JAM+ as a Shopify
  fulfillment service and **proxies** fulfillment requests to admin-ui over **SQS FIFO** — the app
  hydrates the request and drops it on the inbound queue, admin-ui processes it and replies on the
  outbound queue. When `shopify-apps.md` says "the JAM+ backend (OMS)," that's this repo.
- **admin-ui → NetSuite:** order/payment/refund/return ops are pushed to NetSuite RESTlets via the
  OMS dispatch queue (`notification_queue`). Several NetSuite RESTlet contracts are still being
  finalized with the NetSuite team, so some op handlers are drafted/stubbed and throw until the
  contracts land. NetSuite is the ERP and de-facto PIM (same as everywhere else in JAM).
- **admin-ui → the designer:** admin-ui owns designer-data artifacts the customer-facing designer
  reads from S3 (e.g. `fonts.json`, download templates) and is porting the non-Chili legacy designer
  endpoints (analyze / recolor / media) onto a planned separate customer-facing Lambda.
- **Replaces Magento back-office.** admin-ui is the Shopify-era replacement for the Magento
  (`MageForge/*`) adminhtml surface and the legacy Kadro OMS. Specs constantly reference "Magento
  parity" — that's what they mean.

## Working in it

- **Read `CONTEXT.md` first**, then `docs/HANDOFF.md` (freshest running log — the README and some
  `docs/` files lag behind it). The `docs/` tree is thorough but uneven: architecture and the OMS/
  webhook/fulfillment specs are current; some content-area status lines are stale.
- **Implementation is the source of truth** when a spec drifts (per the repo's `CLAUDE.md`).
- Schema is a single versioned DDL file (`schema/schema<VERSION>.sql`) plus timestamped
  `schema/updates/*.sql`. It moves fast — trust the newest update file over the README's version.
- Local dev needs no AWS: dev-bypass auth, filesystem storage, in-process queue. See the repo README.
- Note the repo `CLAUDE.md` still says the canonical path is Malcolm's machine
  (`C:\Users\MalcolmAllen\repos\admin-ui`) — that's the original author's checkout, not Austin's.
