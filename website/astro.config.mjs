// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	site: 'https://grandma3.bambinito.net',
	integrations: [
		starlight({
			title: 'GrandMA3 plugins',
			social: [{ icon: 'github', label: 'Gitlab', href: 'https://github.com/patopesto/GrandMA3-Plugins' }],
			sidebar: [
				{
					label: 'Plugins',
					autogenerate: { directory: 'plugins' },
				},
				{
					label: 'Guides',
					autogenerate: { directory: 'guides' },
				},
				{
					label: 'Reference',
					items: [
						'grandma3/intro',
						{ label: 'v2.2', autogenerate: { directory: 'grandma3/v2.2' }, badge: { text: 'Latest', variant: 'caution' }},
						{ label: 'v2.1', autogenerate: { directory: 'grandma3/v2.1' }, collapsed: true },
						{ label: 'v2.0', autogenerate: { directory: 'grandma3/v2.0' }, collapsed: true },
					],
				},
			],
		}),
	],
});
