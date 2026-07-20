# JAM+ Shopify apps

JAM+ is migrating from Magento2 to Shopify (see platform state in `systems.md`), so new
Shopify apps are a growing part of the stack. There's now a **standard way we build them**: a
serverless React Router 7 app, deployed to AWS Lambda with SST, with a project-agnostic template
you clone to start a new one. If you're building or touching a JAM+ Shopify app, start here.

## The standard stack

| Piece | What we use | Why |
|-------|-------------|-----|
| Framework | **React Router 7** (framework mode, explicit `app/routes.ts`) | It's the Remix successor, full-stack React. Explicit route table beats file-system routing for seeing everything at once. |
| Deploy | **SST** → AWS **Lambda + CloudFront** | Serverless. Infra lives in `sst.config.ts` as plain TypeScript next to the app, no separate IaC repo. |
| Sessions | **DynamoDB** (official `@shopify/shopify-app-session-storage-dynamodb`) | Serverless means no persistent disk, so a SQLite file would vanish on deploy. DynamoDB is cheap at session volume and needs zero babysitting. |
| Async work | **SQS-triggered Lambdas** | Push slow work off the request path so webhooks and loaders stay fast. SST wires the queue as the event source (partial batch failures, retries, DLQ). |
| Logging | Structured JSON to stdout (`app/lib/log/`) → CloudWatch | Single-line JSON, queryable. |
| Shared code | `@jambnc/common` + `@jam/schemas` | Wired in and authed by default (see `packages.md`). |

This is the going-forward standard. **`shop-designer-app` predates it** and runs on ECS (see
`systems.md`); don't copy its hosting pattern for a new app, use the template.

## The repos

- **shopify-jamplus-app-template** (`git@github.com:JAMBNC/shopify-jamplus-app-template.git`,
  `~/coding/js/shopify-jamplus-app-template`) — the **project-agnostic starter**. It's the plain
  Shopify CLI template torn down and rebuilt the JAM+ way: the stack above, GDPR/uninstalled/
  scopes-update webhooks stubbed, and a commented SQS-worker block in `sst.config.ts` plus a
  reference handler at `app/lambda/worker.example.ts`. Clone it, rename, build.
- **shopify-jamplus-fulfillment-app** (`git@github.com:JAMBNC/shopify-jamplus-fulfillment-app.git`,
  `~/coding/js/shopify-jamplus-fulfillment-app`) — the **first real app built on the template**,
  and the reference for how the serverless pattern looks fully wired. It registers JAM+ as a
  Shopify [fulfillment service](https://shopify.dev/docs/apps/build/orders-fulfillment/fulfillment-service-apps)
  and proxies between Shopify and the JAM+ backend (OMS): a fulfillment request comes in, the app
  hydrates it and drops it on an SQS FIFO queue for the backend, the backend replies on a second
  queue with accept/reject + tracking, and the app pushes that back to Shopify. Its `app/lambda/consumer.ts`
  is the real version of the template's worker stub.

## Starting a new app

1. Clone the template, then `shopify app config link` (or `npm run config:link`) to point it at
   your own Shopify app. This rewrites the `client_id` and URLs in `shopify.app.toml`, which still
   point at the app the template was extracted from.
1. Rename it: `name` in `shopify.app.toml`, `shopify.web.toml`, `package.json`, plus `app.name`
   and the `name()` prefix in `sst.config.ts` (that prefix names your AWS resources, keep it short).
1. Set `scopes` in `shopify.app.toml` and keep `SCOPES` in the `.env.*` files in sync.
1. Routes go in `app/routes.ts`, business logic in `app/lib/`, non-web Lambdas in `app/lambda/`.

## Conventions that matter

- **Sessions in DynamoDB everywhere**, including local dev (it hits real DynamoDB, so you need AWS
  creds locally). SST creates the table and injects `DYNAMODB_TABLE`; the switch is in
  `app/shopify.server.ts`.
- **The only secret is an SST secret.** `npx sst secret set ShopifyApiSecret <value> --stage <stage>`.
  Everything else (region, client id, app URL, scopes) is non-secret and lives in **committed**
  `.env.dev` / `.env.prod` files. Never put a secret in those.
- **Thin edges.** Route modules and Lambda handlers authenticate/parse, call a `lib` function, and
  return. Business logic lives in `app/lib/`. Same rule as everywhere else in JAM.
- **Background work goes on SQS**, not in the request. Uncomment the worker block in `sst.config.ts`,
  rename `worker.example.ts` to `worker.ts`, publish with `@aws-sdk/client-sqs`.
- **Parse messages and domain shapes with `@jam/schemas`**, don't hand-define them (the core JAM
  rule, see `schema-pipeline.md`).

## Deploy flow

Two independent pieces, usually both: the **infra/app** (SST → AWS) and the **Shopify config**
(scopes/webhooks/URLs → Shopify).

| Command | What it does |
|---------|--------------|
| `npm run deploy:dev` / `deploy:prod` | SST deploys that stage (web Lambda, CloudFront, DynamoDB) from `.env.dev` / `.env.prod`. |
| `npm run deploy:shopify` | Pushes `shopify.app.toml` config to Shopify. |

**First deploy of a stage is a two-pass dance:** you don't know your CloudFront URL until AWS
gives you one. Deploy once, paste the printed URL into `SHOPIFY_APP_URL` (in the stage `.env`) and
`shopify.app.toml` (`application_url` + `auth.redirect_urls`), then deploy again. If you changed
scopes, reinstall/re-approve the app on the store afterward or calls fail with access-denied.
