import { Err, Ok, Result } from './result';

class OrdinalConversionError extends Error {}
class OrdinalParseError extends Error {}
class NumberParseError extends Error {}

export const parseNumber = (s?: string): Result<number, NumberParseError> => {
   const num = parseFloat(s ?? '');
   if (isNaN(num) || !num) {
      return Err(new NumberParseError());
   }
   return Ok(num);
};

export const fromOrdinal = (s?: string): Result<number, OrdinalParseError> => {
   const lookup = [
      '',
      'first',
      'second',
      'third',
      'fourth',
      'fifth',
      'sixth',
      'seventh',
      'eighth',
      'ninth',
      'tenth',
   ];
   if (!s) return Err(new OrdinalParseError());
   const index = lookup.indexOf(s);
   if (index <= 0) {
      return Err(new OrdinalParseError());
   }
   return Ok(index);
};

export const toOrdinal = (
   n: number
): Result<string, OrdinalConversionError> => {
   const lookup = [
      '',
      'first',
      'second',
      'third',
      'fourth',
      'fifth',
      'sixth',
      'seventh',
      'eighth',
      'ninth',
      'tenth',
   ];
   const val = lookup[n];
   if (!val) {
      return Err(new OrdinalConversionError());
   }
   return Ok(val);
};
