export const isString = (t: unknown): t is string => {
   return typeof t === 'string';
};

export const capitalizeFirst = (str: string): string =>
   str.length > 0 ? str.charAt(0).toUpperCase() + str.slice(1) : str;

export const asHex = (str: string): string =>
   str.startsWith('#') ? str : '#' + str.substring(0, 6);

export const decodeHtmlEntities = (encodedString: string): string => {
   const textarea = document.createElement('textarea');
   textarea.innerHTML = encodedString;
   return textarea.value;
};

export const acronymize = (str: string): string => {
   return str
      .split(' ')
      .map((word) => word.charAt(0).toUpperCase())
      .join('');
};

/** Computes the Levenshtein edit distance between two strings. */
export const levenshtein = (a: string, b: string): number => {
   if (a.length === 0) return b.length;
   if (b.length === 0) return a.length;
   const row: number[] = Array.from({ length: b.length + 1 }, (_, j) => j);
   for (let i = 1; i <= a.length; i++) {
      let prev = row[0];
      row[0] = i;
      for (let j = 1; j <= b.length; j++) {
         const temp = row[j];
         row[j] =
            a[i - 1] === b[j - 1]
               ? prev
               : 1 + Math.min(prev, row[j], row[j - 1]);
         prev = temp;
      }
   }
   return row[b.length];
};

/**
 * Returns a fuzzy match score between a query and a text string.
 * Score 0 means the text contains the query as a substring.
 * Higher scores indicate more edits required; Infinity means no match.
 * Uses sliding-window Levenshtein over the text.
 */
export const fuzzyScore = (query: string, text: string): number => {
   const q = query.toLowerCase();
   const t = text.toLowerCase();
   if (t.includes(q)) return 0;
   if (q.length >= t.length) return levenshtein(q, t);
   let min = Infinity;
   for (let i = 0; i <= t.length - q.length; i++) {
      const dist = levenshtein(q, t.slice(i, i + q.length));
      if (dist < min) min = dist;
   }
   return min;
};
