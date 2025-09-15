import { defineCollection, z } from 'astro:content';
import { docsLoader } from '@astrojs/starlight/loaders';
import { docsSchema } from '@astrojs/starlight/schema';

export const collections = {
    docs: defineCollection({
        loader: docsLoader(),
        schema: docsSchema({
            extend: z.object({
                // Extend Starlight's hero forntmatter to add more parameters for our own Hero component
                hero: z.object({
                    image_attrs: z.object({
                        style: z.string().optional(),
                    }).optional(),
                }).optional(),
            }),
        }),
    }),
};
