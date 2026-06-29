class MissingEnvironmentKeyException extends Error {}

declare global {
   interface Window {
      navi?: {
         environment?: Record<string, string>;
      };
   }
}

export const getEnvironment = (): Record<string, string> => {
   return Object.assign(import.meta.env, window.navi?.environment);
};

export const setEnvironmentValue = (key: string, value: string) => {
   if (!window.navi) {
      window.navi = {};
   }
   if (!window.navi.environment) {
      window.navi.environment = {};
   }
   window.navi.environment[key] = value;
};

export const getOrThrow = (key: string, msg?: string): string => {
   const ret = getEnvironment()[key];
   if (!ret) {
      throw new MissingEnvironmentKeyException(
         msg ?? `The environment key ${key} could not be found`
      );
   }
   return ret;
};

export function getEnvironmentValue(key: string): string | undefined;
export function getEnvironmentValue(
   key: string,
   asType: 'string'
): string | undefined;
export function getEnvironmentValue(
   key: string,
   asType: 'number'
): number | undefined;
export function getEnvironmentValue(
   key: string,
   asType: 'boolean'
): boolean | undefined;
export function getEnvironmentValue(
   key: string,
   asType?: 'string' | 'number' | 'boolean'
): string | number | boolean | undefined {
   if (!asType) asType = 'string';
   const val = getEnvironment()[key];
   if (val == null) return undefined;

   if (asType === 'number') {
      const num = Number(val);
      return Number.isNaN(num) ? undefined : num;
   }

   if (asType === 'boolean') {
      return val === '1' ? true : false;
   }

   return val;
}
