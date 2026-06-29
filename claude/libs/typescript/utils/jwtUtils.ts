export const decodeJwtPayload = (
   token: string
): Record<string, unknown> | undefined => {
   try {
      const parts = token.split('.');

      if (parts.length !== 3) {
         throw new Error('Invalid JWT format');
      }

      const payload = parts[1];
      const base64 = payload.replace(/-/g, '+').replace(/_/g, '/');
      const jsonPayload = decodeURIComponent(
         atob(base64)
            .split('')
            .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
            .join('')
      );

      return JSON.parse(jsonPayload);
   } catch (err) {
      console.error('Failed to decode JWT payload:', err);
      return;
   }
};

export const isJwtExpired = (token: string): boolean => {
   const payload = decodeJwtPayload(token);

   if (!payload || !payload.exp) {
      console.warn('Missing or invalid "exp" in JWT payload.');
      return true;
   }

   const now = Math.floor(Date.now() / 1000);
   return now >= Number(payload.exp);
};
