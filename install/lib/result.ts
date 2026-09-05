/* Local copy rather than an import from claude/libs: that directory is reference
   material for Claude, and its `import './union'` has no file extension, which
   Node's ESM resolver rejects. Same shape, only what the installer uses. */

type Union<Mappings> = {
   [K in keyof Mappings]: { tag: K; value: Mappings[K] };
}[keyof Mappings];

export type Ok<T> = { tag: 'ok'; value: T };
export type Err<E> = { tag: 'err'; value: E };
export type Result<T, E> = Union<{ ok: T; err: E }>;

export const Ok = <T>(value: T): Result<T, never> => ({ tag: 'ok', value });
export const Err = <E>(value: E): Result<never, E> => ({ tag: 'err', value });

export const isOk = <T, E>(result: Result<T, E>): result is Ok<T> => result.tag === 'ok';
export const isErr = <T, E>(result: Result<T, E>): result is Err<E> => result.tag === 'err';

export const map = <T, E, U>(result: Result<T, E>, fn: (value: T) => U): Result<U, E> =>
   isOk(result) ? Ok(fn(result.value)) : result;

export const tryCatch = <T>(fn: () => T): Result<T, string> => {
   try {
      return Ok(fn());
   } catch (error) {
      return Err(error instanceof Error ? error.message : String(error));
   }
};

export const errors = <T, E>(results: readonly Result<T, E>[]): E[] =>
   results.filter(isErr).map((result) => result.value);
