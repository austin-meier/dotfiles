import { Ingredient, TextIngredient } from '@jam/schemas';
import { Sorting } from './arrayUtils';

import { isString } from './stringUtils';
import { Dim, Dimension, Dimensionable } from './dimension';

type Percent = string;
export type InputCoverageMap = Record<string, number | Percent>;
export type CoverageMap = Record<string, Dimension>;

/** Get the adder code for the provided coverage value.
 *  Returns the largest key whose threshold is still <= target */
export const getCoverageAdder = <T>(
   coverageMap: CoverageMap,
   target: Dimension
): T | undefined =>
   Object.entries(coverageMap)
      .filter(([, threshold]) => Dim.lte(threshold, target))
      .toSorted(([, a], [, b]) => Sorting.increasingNumber(a, b))
      .at(-1)?.[0] as T;

/** Takes a coverage map object where the cover map can include percentage values or sq. inch numbers
 *  Will convert the coverageMap to an object of pure numbers based on the current dimensions
 *  of the actual product
 *
 *  ex: {
 *    foil_coverage_sm: 0,
 *    foil_coverage_std: 20%,
 *    foil_coverage_lg: 50%,
 *    foil_coverage_xl: 70%,
 *  }
 */
const parseCoverageMap = (
   coverageMap: InputCoverageMap,
   productDimensions: Dimensionable
): CoverageMap => {
   const normalized = {} as CoverageMap;
   for (const [key, value] of Object.entries(coverageMap)) {
      if (isString(value) && value.includes('%')) {
         const matches = value.match(/\d+/);
         const nValue = matches
            ? Dim.scale(Dim.area(productDimensions), parseInt(matches[0]) / 100)
            : Dim.new(parseInt(value), 'in');
         normalized[key] = nValue;
      }
   }
   return normalized;
};

/** Builds a function that takes a coverage target and returns the closest inclusive adder defined
 *  in the supplied coverageMap
 */
export const coverageAdderFactory = <T>(
   coverageMap: InputCoverageMap,
   productDimensions: Dimensionable
) => {
   const parsedCoverageMap = parseCoverageMap(coverageMap, productDimensions);
   return (target: Dimension) => getCoverageAdder<T>(parsedCoverageMap, target);
};

const calculateTextIngredientCoverage = (
   ingredient: TextIngredient
): Dimension => {
   const lines = ingredient.text.textLines ?? [];
   return lines.reduce(
      (coverage, line) =>
         Dim.add(
            coverage,
            Dim.area({
               width: Dim.deserialize(line.width),
               height: Dim.deserialize(line.height),
            })
         ),
      Dim.new()
   );
};

export const calculateIngredientCoverage = (
   ingredient: Ingredient
): Dimension => {
   if (ingredient.type === 'text') {
   }
   switch (ingredient.type) {
      case 'text':
         return calculateTextIngredientCoverage(ingredient);
      case 'image':
      case 'rectangle':
      case 'fill':
      case 'shape':
         return Dim.area({
            width: Dim.deserialize(ingredient.rect.width),
            height: Dim.deserialize(ingredient.rect.height),
         });
      default:
         return Dim.new();
   }
};

export const calculateCoverage = (ingredients: Ingredient | Ingredient[]) => {
   const arr = Array.isArray(ingredients) ? ingredients : [ingredients];
   return arr
      .map(calculateIngredientCoverage)
      .reduce((acc, d: Dimension) => Dim.add(acc, d), Dim.new());
};
