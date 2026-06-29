/**
 * Retrieves a value from a nested object using an array of keys.
 * Type-safe for paths up to 4 levels deep.
 *
 * @example
 * const state = { user: { profile: { name: 'Alice', age: 30 } } };
 *
 * getIn(state, ['user', 'profile', 'name']); // 'Alice' (typed as string)
 * getIn(state, ['user', 'profile']);         // { name: 'Alice', age: 30 }
 * getIn(state, ['user', 'missing']);         // undefined
 */
export function getIn<T, K1 extends keyof T>(
   obj: T,
   keys: [K1]
): T[K1] | undefined;
export function getIn<T, K1 extends keyof T, K2 extends keyof T[K1]>(
   obj: T,
   keys: [K1, K2]
): T[K1][K2] | undefined;
export function getIn<
   T,
   K1 extends keyof T,
   K2 extends keyof T[K1],
   K3 extends keyof T[K1][K2],
>(obj: T, keys: [K1, K2, K3]): T[K1][K2][K3] | undefined;
export function getIn<
   T,
   K1 extends keyof T,
   K2 extends keyof T[K1],
   K3 extends keyof T[K1][K2],
   K4 extends keyof T[K1][K2][K3],
>(obj: T, keys: [K1, K2, K3, K4]): T[K1][K2][K3][K4] | undefined;
export function getIn(obj: unknown, keys: PropertyKey[]): unknown;

export function getIn(obj: unknown, keys: PropertyKey[]): unknown {
   let current: unknown = obj;

   for (const key of keys) {
      if (current !== null && typeof current === 'object' && key in current) {
         current = (current as Record<PropertyKey, unknown>)[key];
      } else {
         return undefined;
      }
   }

   return current;
}

/**
 * Immutably updates a value at a nested path using an updater function.
 * Creates intermediate objects if the path doesn't exist.
 * Type-safe for paths up to 4 levels deep.
 *
 * @example
 * const state = { user: { profile: { name: 'Alice', age: 30 } } };
 *
 * // Increment age
 * updateIn(state, ['user', 'profile', 'age'], (n) => n + 1);
 * // => { user: { profile: { name: 'Alice', age: 31 } } }
 *
 * // Transform name
 * updateIn(state, ['user', 'profile', 'name'], (s) => s.toUpperCase());
 * // => { user: { profile: { name: 'ALICE', age: 30 } } }
 *
 * // Creates path if missing
 * updateIn({}, ['a', 'b'], () => 'value');
 * // => { a: { b: 'value' } }
 */
export function updateIn<T, K1 extends keyof T>(
   obj: T,
   keys: [K1],
   updater: (val: T[K1]) => T[K1]
): T;
export function updateIn<T, K1 extends keyof T, K2 extends keyof T[K1]>(
   obj: T,
   keys: [K1, K2],
   updater: (val: T[K1][K2]) => T[K1][K2]
): T;
export function updateIn<
   T,
   K1 extends keyof T,
   K2 extends keyof T[K1],
   K3 extends keyof T[K1][K2],
>(
   obj: T,
   keys: [K1, K2, K3],
   updater: (val: T[K1][K2][K3]) => T[K1][K2][K3]
): T;
export function updateIn<
   T,
   K1 extends keyof T,
   K2 extends keyof T[K1],
   K3 extends keyof T[K1][K2],
   K4 extends keyof T[K1][K2][K3],
>(
   obj: T,
   keys: [K1, K2, K3, K4],
   updater: (val: T[K1][K2][K3][K4]) => T[K1][K2][K3][K4]
): T;
export function updateIn<T>(
   obj: T,
   keys: PropertyKey[],
   updater: (val: unknown) => unknown
): T;

export function updateIn(
   obj: unknown,
   keys: PropertyKey[],
   updater: (val: unknown) => unknown
): unknown {
   if (keys.length === 0) {
      return updater(obj);
   }

   const record = (obj ?? {}) as Record<PropertyKey, unknown>;
   const [head, ...tail] = keys;
   const current = record[head];

   return {
      ...record,
      [head]:
         tail.length === 0
            ? updater(current)
            : updateIn(current, tail, updater),
   };
}

/**
 * Immutably removes a key at a nested path.
 * Returns the original object if the path doesn't exist.
 * Type-safe for paths up to 4 levels deep.
 *
 * @example
 * const state = { user: { profile: { name: 'Alice', age: 30 } } };
 *
 * // Remove nested key
 * deleteIn(state, ['user', 'profile', 'age']);
 * // => { user: { profile: { name: 'Alice' } } }
 *
 * // Remove top-level key (return type is Omit<T, K1>)
 * deleteIn(state, ['user']);
 * // => {}
 *
 * // Missing path returns original
 * deleteIn(state, ['user', 'missing', 'key']);
 * // => state (unchanged)
 */
export function deleteIn<T, K1 extends keyof T>(
   obj: T,
   keys: [K1]
): Omit<T, K1>;
export function deleteIn<T, K1 extends keyof T, K2 extends keyof T[K1]>(
   obj: T,
   keys: [K1, K2]
): T;
export function deleteIn<
   T,
   K1 extends keyof T,
   K2 extends keyof T[K1],
   K3 extends keyof T[K1][K2],
>(obj: T, keys: [K1, K2, K3]): T;
export function deleteIn<
   T,
   K1 extends keyof T,
   K2 extends keyof T[K1],
   K3 extends keyof T[K1][K2],
   K4 extends keyof T[K1][K2][K3],
>(obj: T, keys: [K1, K2, K3, K4]): T;
export function deleteIn<T>(obj: T, keys: PropertyKey[]): T;

export function deleteIn(obj: unknown, keys: PropertyKey[]): unknown {
   if (keys.length === 0 || obj === null || typeof obj !== 'object') {
      return obj;
   }

   const record = obj as Record<PropertyKey, unknown>;
   const [head, ...tail] = keys;

   if (!(head in record)) {
      return obj;
   }

   if (tail.length === 0) {
      const { [head]: _, ...rest } = record;
      return rest;
   }

   const nested = record[head];
   if (nested === null || typeof nested !== 'object') {
      return obj;
   }

   return {
      ...record,
      [head]: deleteIn(nested, tail),
   };
}

/**
 * Resolves a delimited path against an object that may have mixed nesting.
 * Greedily matches the longest nested path at each level.
 *
 * @example
 * // All of these return 'value' for path 'a.b.c.d':
 * resolveIn({ a: { b: { c: { d: 'value' } } } }, 'a.b.c.d'); // fully nested
 * resolveIn({ a: { b: { 'c.d': 'value' } } }, 'a.b.c.d');    // partially dotted
 * resolveIn({ 'a.b.c.d': 'value' }, 'a.b.c.d');              // fully dotted
 *
 * // Custom delimiter
 * resolveIn({ a: { 'b/c': 'value' } }, 'a/b/c', '/');
 */
export function resolveIn<T = unknown>(
   obj: Record<string, unknown>,
   path: string,
   delimiter = '.'
): T | undefined {
   if (path in obj) {
      return obj[path] as T;
   }

   const parts = path.split(delimiter);
   if (parts.length < 2) {
      return undefined;
   }

   let current: Record<string, unknown> = obj;
   let accumulated = '';

   for (const part of parts) {
      const key = accumulated ? accumulated + delimiter + part : part;

      if (key in current) {
         const value = current[key];

         if (value !== null && typeof value === 'object') {
            current = value as Record<string, unknown>;
            accumulated = '';
         } else {
            return value as T;
         }
      } else {
         accumulated = key;
      }
   }

   if (accumulated && accumulated in current) {
      return current[accumulated] as T;
   }

   return undefined;
}

export const mapValues = <K extends PropertyKey, V, U>(
   obj: Record<K, V>,
   fn: (value: V, key: K) => U
): Record<K, U> =>
   Object.fromEntries(
      Object.entries(obj).map(([k, v]) => [k, fn(v as V, k as K)])
   ) as Record<K, U>;

export const mapKeys = <K extends PropertyKey, V, J extends PropertyKey>(
   obj: Record<K, V>,
   fn: (key: K, value: V) => J
): Record<J, V> =>
   Object.fromEntries(
      Object.entries(obj).map(([k, v]) => [fn(k as K, v as V), v])
   ) as Record<J, V>;

/**
 * Deep merges two objects. Values from `override` take precedence.
 * Only recurses into plain objects — arrays and other values are replaced wholesale.
 */
export function deepMerge<T extends Record<string, unknown>>(
   base: T,
   override: Partial<T>
): T {
   const result = { ...base } as Record<string, unknown>;
   for (const key in override) {
      const baseVal = result[key];
      const overVal = override[key];
      if (
         overVal !== undefined &&
         typeof baseVal === 'object' &&
         baseVal !== null &&
         !Array.isArray(baseVal) &&
         typeof overVal === 'object' &&
         overVal !== null &&
         !Array.isArray(overVal)
      ) {
         result[key] = deepMerge(
            baseVal as Record<string, unknown>,
            overVal as Record<string, unknown>
         );
      } else if (overVal !== undefined) {
         result[key] = overVal;
      }
   }
   return result as T;
}

export function invert<
   K extends string | number | symbol,
   V extends string | number | symbol,
>(obj: Record<K, V>): Record<V, K>;
export function invert(obj: object): object;
export function invert(obj: object): object {
   const ret: Record<PropertyKey, PropertyKey> = {};
   for (const key in obj) {
      ret[(obj as Record<string, PropertyKey>)[key]] = key;
   }
   return ret;
}

export const isObject = (t: unknown): t is object => {
   return typeof t === 'object';
};
