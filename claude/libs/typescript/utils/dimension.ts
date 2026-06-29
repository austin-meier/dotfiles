/* The root dimension is stored as inches, this is imply because it's the most common used unit we encounter,
   upon creation all items are converted to inches and only at consumption time are they converted back
   This keeps logic simple. Dimension is an opaque type to help type system enforcement
   To pull it back to a number, use asUnit() and supply the unit you want to be explicit */
declare const DimensionBrand: unique symbol;
export type Dimension = number & { readonly [DimensionBrand]: true };

export type DimensionUnit = 'in' | 'pt' | 'cm' | 'm' | 'mm';

export interface Dimensionable {
   width: Dimension;
   height: Dimension;
}

/* Exact ratios (inches per unit) — kept as expressions, not rounded decimals,
   so conversions through the inch pivot carry only float64 epsilon rather than
   constant truncation error. Do not "simplify" these to decimal literals. */
const inchesPerUnit: Record<DimensionUnit, number> = {
   in: 1,
   pt: 1 / 72,
   cm: 1 / 2.54,
   m: 1000 / 25.4,
   mm: 1 / 25.4,
};

const newDimension = (
   value: number = 0,
   unit: DimensionUnit = 'in'
): Dimension => (value * inchesPerUnit[unit]) as Dimension;

const asUnit = (d: Dimension, unit: DimensionUnit): number =>
   d / inchesPerUnit[unit];

const fromPixels = (pixels: number, dpi: number): Dimension =>
   (pixels / dpi) as Dimension;

const asPixels = (d: Dimension, dpi: number): number => (d as number) * dpi;

const add = (a: Dimension, b: Dimension): Dimension =>
   ((a as number) + (b as number)) as Dimension;

const subtract = (a: Dimension, b: Dimension): Dimension =>
   ((a as number) - (b as number)) as Dimension;

const multiply = (a: Dimension, b: Dimension): Dimension =>
   ((a as number) * (b as number)) as Dimension;

const divide = (a: Dimension, b: Dimension): Dimension =>
   ((a as number) / (b as number)) as Dimension;

const scale = (d: Dimension, factor: number): Dimension =>
   ((d as number) * factor) as Dimension;

const display = (d: Dimension, unit: DimensionUnit): string =>
   `${asUnit(d, unit)} ${unit}`;

const lt = (a: Dimension, b: Dimension): boolean => a < b;
const lte = (a: Dimension, b: Dimension): boolean => a <= b;
const gt = (a: Dimension, b: Dimension): boolean => a > b;
const gte = (a: Dimension, b: Dimension): boolean => a >= b;

const area = (d: Dimensionable): Dimension => multiply(d.width, d.height);

declare global {
   interface Window {
      alchemy?: {
         dimension?: {
            dpi?: () => number;
         };
      };
   }
}

const deserialize = ({
   v,
   u,
   dpi,
}: {
   v: number;
   u: 'mm' | 'px' | 'pt' | 'in' | 'm';
   dpi?: number;
}): Dimension =>
   u === 'px'
      ? fromPixels(v, dpi || window.alchemy?.dimension?.dpi?.() || 96)
      : newDimension(v, u);

const serialize = (d: Dimension) => ({
   v: d as number,
   u: 'in' as const,
});

const rectangle = (
   width = newDimension(0, 'in'),
   height = newDimension(0, 'in')
): Dimensionable => ({ width, height });

export const Dim = {
   new: newDimension,
   rectangle,
   asUnit,
   fromPixels,
   asPixels,
   add,
   subtract,
   multiply,
   divide,
   scale,
   display,
   lt,
   lte,
   gt,
   gte,
   area,

   deserialize,
   serialize,
};
