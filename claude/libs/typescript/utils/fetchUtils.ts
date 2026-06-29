import { Auth } from '@jam/schemas';
import { Err, Ok, Result } from './result';

type FetchFromOptions = RequestInit & {
   auth?: Auth;
};

const fetchOAuthToken = async (
   tokenUrl: string,
   body: Record<string, string>
): Promise<string> => {
   const resp = await fetch(tokenUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams(body).toString(),
   });
   if (!resp.ok)
      throw new Error(`Token request failed with status ${resp.status}`);
   const { access_token } = await resp.json();
   return access_token as string;
};

const applyAuth = async (
   auth: Auth,
   url: string,
   init: RequestInit
): Promise<{ url: string; init: RequestInit }> => {
   const headers = new Headers(init.headers);

   switch (auth.type) {
      case 'bearer':
         headers.set('Authorization', `Bearer ${auth.token}`);
         break;
      case 'basic': {
         const encoded = btoa(`${auth.username}:${auth.password}`);
         headers.set('Authorization', `Basic ${encoded}`);
         break;
      }
      case 'apiKey':
         if (auth.in === 'header') {
            headers.set(auth.headerName, auth.key);
         } else {
            const sep = url.includes('?') ? '&' : '?';
            url = `${url}${sep}${encodeURIComponent(auth.headerName)}=${encodeURIComponent(auth.key)}`;
         }
         break;
      case 'oauth2_client_credentials': {
         const token = await fetchOAuthToken(auth.tokenUrl, {
            grant_type: 'client_credentials',
            client_id: auth.clientId,
            client_secret: auth.clientSecret,
            ...(auth.scopes ? { scope: auth.scopes.join(' ') } : {}),
         });
         headers.set('Authorization', `Bearer ${token}`);
         break;
      }
      case 'oauth2_refresh_token': {
         const token = await fetchOAuthToken(auth.tokenUrl, {
            grant_type: 'refresh_token',
            refresh_token: auth.refreshToken,
            client_id: auth.clientId,
            ...(auth.clientSecret ? { client_secret: auth.clientSecret } : {}),
         });
         headers.set('Authorization', `Bearer ${token}`);
         break;
      }
      case 'oauth2_authorization_code':
         /* Requires a user-facing redirect flow — not implemented */
         break;
   }

   return { url, init: { ...init, headers } };
};

export const fetchFrom = async <T>(
   url: string,
   options?: FetchFromOptions
): Promise<Result<T, Error>> => {
   try {
      const { auth, ...init } = options ?? {};
      const resolved = auth ? await applyAuth(auth, url, init) : { url, init };
      const response = await fetch(resolved.url, resolved.init);
      if (!response.ok) {
         throw new Error(`Request failed with status ${response.status}`);
      }
      return Ok(await response.json());
   } catch (e) {
      return Err(e instanceof Error ? e : new Error(String(e)));
   }
};
