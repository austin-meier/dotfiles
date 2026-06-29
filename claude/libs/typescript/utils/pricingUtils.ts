import { Product, TierPrice } from '@jam/schemas';
import { first, last } from './arrayUtils';
import { getProductPriceTiers } from '../lenses/productLens';

export const sortTiersByQty = <T extends { startingAtQty: number }>(
   tiers: T[] | undefined
): T[] => (tiers ?? []).toSorted((a, b) => a.startingAtQty - b.startingAtQty);

/**
 * Find the index of the best quantity option by unit price.
 *
 * Given an array of candidate quantities and a set of price tiers, this function
 * computes the unit price for each candidate quantity and returns the index of
 * the candidate that yields the lowest unit price. If multiple candidates have
 * the same unit price, the last one encountered (largest quantity after sort)
 * will be chosen because options are sorted ascending before evaluation.
 *
 * @param options - Array of candidate quantities (numbers). Can be in any order.
 * @param priceTiers - Array of TierPrice objects used to determine unit prices.
 * @returns The index (into the sorted `options` array) of the best quantity option.
 *
 * @example
 * // priceTiers give cheaper per-unit price at higher quantities
 * const options = [1, 5, 10];
 * const bestIndex = getBestQuantityOption(options, priceTiers);
 */
export const getBestQuantityOption = (
   options: number[],
   priceTiers: TierPrice[]
): number =>
   options
      .toSorted((a, b) => a - b)
      .reduce(
         ([bestIdx, bestPrice], n, idx) => {
            const price = getUnitPriceAtTier(priceTiers, n);
            return price <= bestPrice ? [idx, price] : [bestIdx, bestPrice];
         },
         [0, getUnitPriceAtTier(priceTiers, options[0])]
      )[0];

/**
 * Return the applicable tier for a given quantity.
 *
 * The function accepts an array of tier-like objects (must have `startingAtQty`) and a
 * quantity. Tiers may be supplied in any order. The function sorts tiers by
 * `startingAtQty`, finds all tiers with `startingAtQty <= quantity`, and returns
 * the last of those (the most specific applicable tier). If no tier matches
 * (quantity smaller than all `startingAtQty`), the first tier from the sorted
 * list is returned as a sensible fallback. If `tiers` is empty or undefined,
 * `undefined` is returned.
 *
 * @template T - type of tier object (must include `startingAtQty: number`).
 * @param tiers - Array of tier objects or undefined.
 * @param quantity - The quantity to evaluate against the tiers.
 * @returns The applicable tier object or `undefined` if no tiers are provided.
 *
 * @example
 * const tiers = [{ startingAtQty: 1, price: 5 }, { startingAtQty: 10, price: 4 }];
 * getTier(tiers, 12); // returns the tier with startingAtQty 10
 */
export const getTier = <T extends { startingAtQty: number }>(
   tiers: T[] | undefined,
   quantity: number
): T | undefined => {
   const sorted = sortTiersByQty(tiers);
   const validTiers = sorted.filter((t) => quantity >= t.startingAtQty);
   return validTiers.length ? last(validTiers) : first(sorted);
};

/**
 * Get the unit price for a specific quantity from price tiers.
 *
 * Looks up the applicable tier for `quantity` and returns its `price` value.
 * If no tier is found, returns 0.
 *
 * @param tiers - Array of TierPrice objects.
 * @param quantity - Quantity to price.
 * @returns Unit price (number) for the provided quantity, or 0 if no tiers.
 */
export const getUnitPriceAtTier = (
   tiers: TierPrice[] | undefined,
   quantity: number
): number => getTier(tiers, quantity)?.price ?? 0;

/**
 * Get the sale unit price for a specific quantity from price tiers.
 *
 * Returns the `salePrice` value for the applicable tier, or 0 if there is no
 * sale price or no tiers. Useful when a product is discounted below the
 * normal unit price.
 *
 * @param tiers - Array of TierPrice objects.
 * @param quantity - Quantity to price.
 * @returns Sale unit price (number) for the provided quantity, or 0.
 */
export const getSalePriceAtTier = (
   tiers: TierPrice[] | undefined,
   quantity: number
): number | undefined => getTier(tiers, quantity)?.salePrice;

/**
 * Determine the price used when adding items to cart for a specific quantity.
 *
 * If the applicable tier has a `salePrice`, that value is returned. Otherwise
 * the regular `price` is returned. If no tier matches, returns 0.
 *
 * @param tiers - Array of TierPrice objects.
 * @param quantity - Quantity being added to cart.
 * @returns The effective add-to-cart unit price.
 */
export const getAddToCartPrice = (
   tiers: TierPrice[],
   quantity: number
): number => {
   const tier = getTier(tiers, quantity);
   if (!tier) return 0;
   return getAddToCartPriceAtTier(tier, quantity);
};

export const getAddToCartPriceAtTier = (
   tier: TierPrice,
   quantity: number
): number => {
   return (tier?.salePrice ?? tier?.price ?? 0) * quantity;
};

/**
 * Compute the total price for a given quantity using tier unit price.
 *
 * Multiplies the unit price (from `getUnitPriceAtTier`) by the quantity.
 *
 * @param tiers - Array of TierPrice objects.
 * @param quantity - Quantity to price.
 * @returns Total price (number) for the requested quantity.
 */
export const getTotalPriceAtTier = (
   tiers: TierPrice[] | undefined,
   quantity: number
): number => {
   const salePrice = getSalePriceAtTier(tiers, quantity);
   const unitPrice = getUnitPriceAtTier(tiers, quantity);
   return quantity * (salePrice || unitPrice);
};

export const getTotalUnitPriceAtTier = (
   tiers: TierPrice[],
   quantity: number
): number => {
   const salePrice = getSalePriceAtTier(tiers, quantity);
   const unitPrice = getUnitPriceAtTier(tiers, quantity);
   return salePrice || unitPrice;
};

/**
 * Return the first tier where `startingAtQty` is greater than 1.
 *
 * Tiers are sorted ascending by `startingAtQty` and the first tier with a
 * `startingAtQty > 1` is returned. Useful for detecting volume pricing tiers
 * that start above a single unit.
 *
 * @param tiers - Array of TierPrice objects.
 * @returns The first non-unit tier or `undefined` if none exists.
 */
export const getFirstNonUnitPriceTier = (
   tiers: TierPrice[]
): TierPrice | undefined => {
   const sorted = sortTiersByQty(tiers);
   return sorted.find((t) => t.startingAtQty > 1);
};

export const getFirstBundlePrice = (
   p: Product
): { price: number; quantity: number; isSale: boolean } => {
   const tiers = getProductPriceTiers(p);
   const tier = getFirstNonUnitPriceTier(getProductPriceTiers(p)) || tiers[0];
   const qty =
      ((tier?.startingAtQty > 1 ? tier.startingAtQty : undefined) ||
         (p.purchaseOptions?.suggestedQuantityDisplays ?? [])[0] ||
         p.purchaseOptions?.minSaleQty) ??
      1;
   return {
      isSale: tier?.salePrice !== undefined,
      price: (tier?.salePrice || tier?.price || 0) * qty,
      quantity: qty,
   };
};
