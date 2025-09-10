// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	integrations: [
		starlight({
			title: 'GrandMA3 plugins',
			social: [{ icon: 'github', label: 'Gitlab', href: 'https://gitlab.com/patopest/grandma3-plugins' }],
			sidebar: [
				{
					label: 'Plugins',
					autogenerate: { directory: 'plugins' },
				},
				{
					label: 'Reference',
					// items: [
					// 	// Each item here is one entry in the navigation menu.
					// 	{ label: 'Example Guide', slug: 'guides/example' },
					// ],
					autogenerate: { directory: 'grandma3' },
				},
			],
		}),
	],
});
