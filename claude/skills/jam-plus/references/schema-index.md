# JAM+ domain schema index

Catalog of domain models in the `schema` repo (`~/coding/schema/jam`). All paths are under
`resources/schemas/v1/`. Consume the generated types as `@jam/schemas`; edit the source here.
**`manual/` = hand-written JSON Schema; everything else is generated from Java POJOs** under
`src/main/java/com/jam/schema/v1/**` (see `schema-pipeline.md`).

> Snapshot of the `v1` model set — regenerate by listing `resources/schemas/v1/**` when it drifts.

## Core commerce

| Object | Path | Notes |
|--------|------|-------|
| `Product` | `Product.json` | Core product model. |
| `Category` | `Category.json` | Product categorization. |
| `Order` | `Order.json` | Customer order. |
| `Customer` | `Customer.json` | Customer record. |
| `Address` | `Address.json` | Address (shipping/billing). |
| `Shipment` | `Shipment.json` | Shipment/fulfillment. |
| `Vendor` | `Vendor.json` | Vendor/supplier. |
| `Dimension` | `Dimension.json` | Physical dimension (pairs with `dimension` util / branded type). |
| `DisplayGroup` | `DisplayGroup.json` | Groupings of products for the PDP (product display page): products grouped by common pivots, plus the pivots they're grouped by. |

## Design & color

| Object | Path | Notes |
|--------|------|-------|
| `DesignState` | `DesignState.json` | **The design a customer produces in the designer** — travels with the order. Central model. |
| `DesignerConfig` | `designerconfig/DesignerConfig.json` | Configuration that drives the designer. |
| `Color` | `color/Color.json` | Color model. |
| `ColorPalette` | `color/ColorPalette.json` | Palette of colors. |
| `VendorColor` | `color/VendorColor.json` | Vendor-specific color. |

## Designer integration (mostly `manual/`)

| Object | Path | Notes |
|--------|------|-------|
| `DesignerInitializationPayload` | `manual/DesignerInitializationPayload.json` | Payload to boot/initialize the designer (pairs with `@jamplus/kronos`). |
| `DesignerEvents` | `manual/DesignerEvents.json` | Events emitted over postMessage from a designer instance (e.g. hermes); `@jamplus/kronos` carries them to the parent window. |
| `DesignerRest` | `manual/DesignerRest.json` | The REST (Swagger) schema for the endpoints the frontend designer calls for designer operations. |
| `DesignVerification` | `manual/DesignVerification.json` | Format returned by a backend endpoint, consumed by a ReactEcom component the prepress team uses to verify designs are print-ready. |
| `Auth` | `manual/Auth.json` | Auth model. |
| `Fonts` | `manual/Fonts.json` | Fonts (pairs with `@jambnc/font`). |
| `UiLabels` | `manual/UiLabels.json` | UI label strings. |

## Data feeds (NetSuite ↔ storefronts)

Relevant to the NetSuite → Magento/Shopify feed work.

| Object | Path |
|--------|------|
| `ProductDataFeed` | `manual/ProductDataFeed.json` |
| `PricingDataFeed` | `manual/PricingDataFeed.json` |
| `InventoryDataFeed` | `manual/InventoryDataFeed.json` |

## Site & misc

| Object | Path | Notes |
|--------|------|-------|
| `ProductReview` | `productreview/ProductReview.json` | Product review. |
| `Attribute` | `site/Attribute.json` | A Magento product attribute and how it relates. Used alongside `DisplayGroup` to drive how pivots render (products pivot on attributes) — defines frontend rendering of an attribute, etc. |
| `Badge` | `site/Badge.json` | From Magento; an abstract badge rendered alongside product content (mainly images), e.g. a "30%" badge. Captures placement/location etc. |

<!-- TODO: add key fields for the hottest models (DesignState, Product, Order,
     DesignerInitializationPayload) if that proves useful during development. -->
