import { memoize } from './functionUtils';

export const parseCookie = (cookieString: string): Record<string, unknown> => {
   return cookieString
      .split(';')
      .map((cookie) => cookie.trim().split('='))
      .reduce((acc: Record<string, unknown>, [key, value]) => {
         try {
            acc[decodeURIComponent(key)] = decodeURIComponent(value);
         } catch (_) {
            acc[key] = value;
         }
         return acc;
      }, {});
};

export const getDocumentCookie = memoize(() => parseCookie(document.cookie));
