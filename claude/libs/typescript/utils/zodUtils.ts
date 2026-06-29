import { z } from 'zod';

export const extractDefaults = <T extends z.ZodTypeAny>(
   schema: T
): Partial<z.infer<T>> => {
   if (schema instanceof z.ZodOptional || schema instanceof z.ZodNullable) {
      return extractDefaults(schema.unwrap() as z.ZodTypeAny);
   }

   if (schema instanceof z.ZodDefault) {
      const inner = schema.def.innerType;
      if (inner instanceof z.ZodObject) {
         return extractDefaults(inner) as Partial<z.infer<T>>;
      }
      return schema.def.defaultValue as Partial<z.infer<T>>;
   }

   if (schema instanceof z.ZodObject) {
      return Object.fromEntries(
         Object.entries(schema.shape)
            .map(([key, value]) => [
               key,
               extractDefaults(value as z.ZodTypeAny),
            ])
            .filter(([, v]) => v !== undefined)
      ) as Partial<z.infer<T>>;
   }

   return undefined as unknown as Partial<z.infer<T>>;
};
